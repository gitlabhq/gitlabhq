/**
 * Merges E2E frontend test mappings with Jest test mappings.
 *
 * E2E mappings (test -> sources) from `js-coverage-by-example-*.json` are inverted
 * to source -> tests format, then merged with Jest test mappings from
 * `jest-test-mapping/jest-source-to-test.json` to produce a combined mapping file.
 *
 * The merged mapping enables multi-category coverage attribution:
 * - Files covered only by Jest tests show Jest test attribution
 * - Files covered only by E2E tests show E2E test attribution
 * - Files covered by both show attribution from both test types
 */

const fs = require('fs');
const path = require('path');
const glob = require('glob');

const E2E_MAPPING_GLOB = 'coverage-e2e-frontend/js-coverage-by-example-*.json';
const JEST_MAPPING_PATH = 'jest-test-mapping/jest-source-to-test.json';
const MERGED_MAPPING_PATH = 'jest-test-mapping/merged-source-to-test.json';

/**
 * Builds nested path structure for test locations.
 * @param {string[]} testLocations - Array of test locations (e.g., "spec/qa/specs/test_spec.rb:123")
 * @returns {Object} Nested path structure
 */
function buildNestedTestPaths(testLocations) {
  const nested = {};

  testLocations.forEach((testLocation) => {
    const parts = testLocation.split('/');
    let current = nested;

    parts.forEach((part, index) => {
      if (index === parts.length - 1) {
        current[part] = 1;
      } else {
        if (!current[part]) {
          current[part] = {};
        }
        current = current[part];
      }
    });
  });

  return nested;
}

/**
 * Deep merges two nested test path structures.
 * @param {Object} target - Target nested structure
 * @param {Object} source - Source nested structure to merge
 * @returns {Object} Merged nested structure
 */
function deepMergeTestPaths(target, source) {
  const result = { ...target };

  Object.entries(source).forEach(([key, value]) => {
    if (typeof value === 'object' && value !== null && typeof result[key] === 'object') {
      result[key] = deepMergeTestPaths(result[key], value);
    } else {
      result[key] = value;
    }
  });

  return result;
}

/**
 * Loads and merges all E2E mapping files from artifacts.
 * @returns {Object} Merged test -> sources mapping
 */
function loadE2EMappings() {
  const files = glob.sync(E2E_MAPPING_GLOB);

  if (files.length === 0) {
    console.log('No E2E mapping files found');
    return {};
  }

  console.log(`Found ${files.length} E2E mapping files`);

  const merged = {};

  files.forEach((file) => {
    try {
      const data = JSON.parse(fs.readFileSync(file, 'utf8'));

      if (typeof data !== 'object' || data === null || Array.isArray(data)) {
        console.warn(`Warning: ${file} does not contain a valid mapping object, skipping`);
        return;
      }

      Object.entries(data).forEach(([testLocation, sourcePaths]) => {
        if (!merged[testLocation]) {
          merged[testLocation] = [];
        }

        const sources = Array.isArray(sourcePaths) ? sourcePaths : [sourcePaths];
        sources.forEach((source) => {
          if (!merged[testLocation].includes(source)) {
            merged[testLocation].push(source);
          }
        });
      });
    } catch (error) {
      console.warn(`Warning: Failed to parse ${file}: ${error.message}`);
    }
  });

  return merged;
}

/**
 * Inverts mapping from test -> sources to source -> tests.
 * @param {Object} testToSources - Mapping of test locations to source paths
 * @returns {Object} Mapping of source paths to test locations
 */
function invertMapping(testToSources) {
  const sourceToTests = {};

  Object.entries(testToSources).forEach(([testLocation, sourcePaths]) => {
    const sources = Array.isArray(sourcePaths) ? sourcePaths : [sourcePaths];

    sources.forEach((sourcePath) => {
      // Normalize source path (remove leading ./ if present)
      const normalizedPath = sourcePath.replace(/^\.\//, '');

      if (!sourceToTests[normalizedPath]) {
        sourceToTests[normalizedPath] = [];
      }

      if (!sourceToTests[normalizedPath].includes(testLocation)) {
        sourceToTests[normalizedPath].push(testLocation);
      }
    });
  });

  return sourceToTests;
}

/**
 * Converts a flat source -> tests mapping to Crystalball nested format.
 * @param {Object} sourceToTests - Flat mapping of source paths to test locations
 * @returns {Object} Crystalball-format nested mapping
 */
function convertToCrystalballFormat(sourceToTests) {
  const crystalballMap = {};

  Object.entries(sourceToTests).forEach(([sourceFile, testLocations]) => {
    crystalballMap[sourceFile] = buildNestedTestPaths(testLocations);
  });

  return crystalballMap;
}

/**
 * Loads Jest test mapping from file.
 * @returns {Object|null} Jest mapping in Crystalball format, or null if not found
 */
function loadJestMapping() {
  if (!fs.existsSync(JEST_MAPPING_PATH)) {
    console.log(`Jest mapping not found at ${JEST_MAPPING_PATH}`);
    return null;
  }

  try {
    const data = JSON.parse(fs.readFileSync(JEST_MAPPING_PATH, 'utf8'));
    console.log(`Loaded Jest mapping: ${Object.keys(data).length} source files`);
    return data;
  } catch (error) {
    console.error(`Failed to load Jest mapping: ${error.message}`);
    return null;
  }
}

/**
 * Merges two Crystalball-format mappings, combining test paths for each source.
 * @param {Object} jestMapping - Jest source -> tests mapping
 * @param {Object} e2eMapping - E2E source -> tests mapping (in Crystalball format)
 * @returns {Object} Merged mapping
 */
function mergeMappings(jestMapping, e2eMapping) {
  const merged = { ...jestMapping };

  Object.entries(e2eMapping).forEach(([sourceFile, testPaths]) => {
    if (!merged[sourceFile]) {
      merged[sourceFile] = testPaths;
    } else {
      // Deep merge the nested test paths
      merged[sourceFile] = deepMergeTestPaths(merged[sourceFile], testPaths);
    }
  });

  return merged;
}

/**
 * Saves the merged mapping to file.
 * @param {Object} mapping - Merged mapping to save
 */
function saveMergedMapping(mapping) {
  const outputDir = path.dirname(MERGED_MAPPING_PATH);

  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  fs.writeFileSync(MERGED_MAPPING_PATH, JSON.stringify(mapping, null, 2), 'utf8');
  console.log(`Saved merged mapping to ${MERGED_MAPPING_PATH}`);
}

/**
 * Main function to merge E2E and Jest test mappings.
 */
function main() {
  console.log('=== E2E Frontend Test Mapping Merger ===');

  const e2eTestToSources = loadE2EMappings();

  if (Object.keys(e2eTestToSources).length === 0) {
    console.log('No E2E mappings to merge, skipping...');
    return;
  }

  const e2eSourceToTests = invertMapping(e2eTestToSources);
  console.log(`Inverted E2E mapping: ${Object.keys(e2eSourceToTests).length} source files`);

  const e2eCrystalballFormat = convertToCrystalballFormat(e2eSourceToTests);
  const jestMapping = loadJestMapping();

  if (!jestMapping) {
    console.log('No Jest mapping found, saving E2E mapping only');
    saveMergedMapping(e2eCrystalballFormat);
    console.log('=== Merge complete ===');
    return;
  }

  const mergedMapping = mergeMappings(jestMapping, e2eCrystalballFormat);
  console.log(`Merged mapping: ${Object.keys(mergedMapping).length} source files`);

  saveMergedMapping(mergedMapping);
  console.log('=== Merge complete ===');
}

module.exports = {
  loadE2EMappings,
  invertMapping,
  convertToCrystalballFormat,
  buildNestedTestPaths,
  loadJestMapping,
  mergeMappings,
  deepMergeTestPaths,
  saveMergedMapping,
  main,
  E2E_MAPPING_GLOB,
  JEST_MAPPING_PATH,
  MERGED_MAPPING_PATH,
};

if (require.main === module) {
  main();
}
