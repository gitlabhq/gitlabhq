#!/usr/bin/env node
// Converts per-example Istanbul E2E coverage into the line-hit format the
// gitlab_quality-test_tooling gem consumes via --per-test-coverage.
//
// In:  { exampleId: { absSourcePath: <Istanbul FileCoverage> } }
// Out: same nesting, values become 0-indexed line-hit arrays matching the Ruby
//      Coverage format (null = non-executable, 0 = executable not hit, N = hits).

const { readFileSync, writeFileSync, mkdirSync } = require('fs');
const { resolve, relative, basename, join } = require('path');
const { sync } = require('glob');
const { createFileCoverage } = require('istanbul-lib-coverage');

const inputGlob = process.argv[2] || resolve(__dirname, '../../qa/tmp/js-istanbul-coverage-*.json');
const outputDir = process.argv[3] || resolve(__dirname, '../../coverage-e2e-per-test-frontend');
const projectRoot = resolve(__dirname, '../../');

mkdirSync(outputDir, { recursive: true });

// Strips the build-time absolute prefix so stored paths are project-root-relative,
// matching how other coverage tools (Coverband, SimpleCov) record source paths.
function normalizePath(absPath) {
  const rel = relative(projectRoot, absPath);
  return rel.startsWith('..') ? basename(absPath) : rel;
}

// getLineCoverage() returns 1-based line numbers; we shift to 0-based and leave
// gaps null (non-executable lines).
function toLineHitsArray(rawCoverage) {
  // jest wraps FileCoverage data under a `data` key in some versions
  const fc = createFileCoverage(rawCoverage.data ? rawCoverage.data : rawCoverage);
  const lineCoverage = fc.getLineCoverage();

  const lineNumbers = Object.keys(lineCoverage).map(Number);
  if (lineNumbers.length === 0) return null;

  const maxLine = Math.max(...lineNumbers);
  const lineHits = new Array(maxLine).fill(null);
  for (const [lineStr, hits] of Object.entries(lineCoverage)) {
    lineHits[Number(lineStr) - 1] = hits;
  }
  return lineHits;
}

const inputFiles = sync(inputGlob);
console.log(`Found ${inputFiles.length} Istanbul per-example coverage file(s)`);

if (inputFiles.length === 0) {
  console.warn('No input files matched — nothing to convert.');
  process.exit(0);
}

let totalExamples = 0;

for (const inputFile of inputFiles) {
  let perExampleData;
  try {
    perExampleData = JSON.parse(readFileSync(inputFile, 'utf-8'));
  } catch (err) {
    console.warn(`Skipping ${basename(inputFile)}: ${err.message}`);
    continue;
  }
  const converted = {};

  for (const [exampleId, fileCoverages] of Object.entries(perExampleData)) {
    const convertedFiles = {};
    for (const [absPath, rawCoverage] of Object.entries(fileCoverages)) {
      const lineHits = toLineHitsArray(rawCoverage);
      if (!lineHits) continue;
      convertedFiles[normalizePath(absPath)] = lineHits;
    }
    if (Object.keys(convertedFiles).length > 0) {
      converted[exampleId] = convertedFiles;
    }
  }

  const outName = basename(inputFile).replace(
    'js-istanbul-coverage-',
    'per-test-coverage-e2e-frontend-',
  );
  const outPath = join(outputDir, outName);
  writeFileSync(outPath, JSON.stringify(converted));
  totalExamples += Object.keys(converted).length;
  console.log(
    `Converted ${basename(inputFile)}: ${Object.keys(converted).length} examples → ${outName}`,
  );
}

console.log(`Done. Total examples: ${totalExamples}`);
