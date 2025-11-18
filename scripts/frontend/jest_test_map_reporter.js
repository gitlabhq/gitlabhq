const fs = require('fs');
const path = require('path');

/**
 * Jest reporter that generates a test map from coverage data.
 *
 * Builds a mapping of source files to the test files that execute them.
 * Requires Jest to be run with --coverage flag.
 *
 * Output format matches Crystalball structure for RSpec tests:
 * {
 *   "app/assets/javascripts/user.js": {
 *     "spec": { "frontend": { "user_spec.js": 1 } }
 *   }
 * }
 */
class JestTestMapReporter {
  constructor(globalConfig, reporterOptions) {
    this.globalConfig = globalConfig;
    this.options = reporterOptions || {};
    this.coverageEnabled = globalConfig.collectCoverage;
    this.testToSourceMap = {};
    this.sourceToTestMap = {};
  }

  onTestResult(test, testResult) {
    if (!this.coverageEnabled || !testResult.coverage) {
      return;
    }

    const testFilePath = JestTestMapReporter.relativePath(testResult.testFilePath);

    const sourceFiles = Object.keys(testResult.coverage)
      .map((f) => JestTestMapReporter.relativePath(f))
      .filter((f) => JestTestMapReporter.shouldIncludeSourceFile(f));

    this.testToSourceMap[testFilePath] = sourceFiles;

    sourceFiles.forEach((sourceFile) => {
      if (!this.sourceToTestMap[sourceFile]) {
        this.sourceToTestMap[sourceFile] = [];
      }
      if (!this.sourceToTestMap[sourceFile].includes(testFilePath)) {
        this.sourceToTestMap[sourceFile].push(testFilePath);
      }
    });
  }

  onRunComplete() {
    if (!this.coverageEnabled) {
      return;
    }

    const outputDir = this.getOutputDir();
    const sourceToTestPath = path.join(outputDir, 'jest-source-to-test.json');

    try {
      if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
      }

      const crystalballFormat = JestTestMapReporter.convertToCrystalballFormat(
        this.sourceToTestMap,
      );

      fs.writeFileSync(sourceToTestPath, JSON.stringify(crystalballFormat, null, 2), 'utf8');

      console.log(`\n✓ Jest test map written to ${sourceToTestPath}`);
      console.log(`  Tests mapped: ${Object.keys(this.testToSourceMap).length}`);
      console.log(`  Source files covered: ${Object.keys(this.sourceToTestMap).length}`);
    } catch (error) {
      console.error(`\n✗ Failed to write test map: ${error.message}`);
    }
  }

  getOutputDir() {
    if (this.options.outputDir) {
      return this.options.outputDir;
    }

    return 'jest-test-mapping';
  }

  static convertToCrystalballFormat(sourceToTestMap) {
    const crystalballMap = {};

    Object.entries(sourceToTestMap).forEach(([sourceFile, testFiles]) => {
      crystalballMap[sourceFile] = JestTestMapReporter.buildNestedTestPaths(testFiles);
    });

    return crystalballMap;
  }

  static buildNestedTestPaths(testFiles) {
    const nested = {};

    testFiles.forEach((testFile) => {
      const parts = testFile.split('/');
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

  static shouldIncludeSourceFile(filePath) {
    if (filePath.includes('node_modules')) {
      return false;
    }

    if (filePath.includes('spec/') || filePath.match(/_spec\.(js|ts|jsx|tsx)$/)) {
      return false;
    }

    if (filePath.match(/\.(json|md|txt|yml|yaml)$/)) {
      return false;
    }

    return true;
  }

  static relativePath(absolutePath) {
    const cwd = process.cwd();
    const relative = path.relative(cwd, absolutePath);
    return relative.startsWith('./') ? relative.slice(2) : relative;
  }
}

module.exports = JestTestMapReporter;
