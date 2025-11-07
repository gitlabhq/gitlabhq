const fs = require('fs');
const path = require('path');

/**
 * Jest reporter that outputs test metadata in JSON format matching the RSpec
 * JSON formatter structure (spec/support/formatters/json_formatter.rb).
 */
class JestJsonReporter {
  constructor(globalConfig, reporterOptions) {
    this.globalConfig = globalConfig;
    this.options = reporterOptions || {};
    this.startTime = Date.now();
  }

  onRunComplete(testContexts, results) {
    const duration = (Date.now() - this.startTime) / 1000;

    const examples = [];
    results.testResults.forEach((testResult) => {
      testResult.testResults.forEach((testCaseResult) => {
        examples.push(JestJsonReporter.formatTestCase(testResult, testCaseResult));
      });
    });

    const summary = {
      duration,
      example_count: results.numTotalTests,
      failure_count: results.numFailedTests,
      pending_count: results.numPendingTests,
      todo_count: results.numTodoTests,
    };

    const outputData = {
      examples,
      summary,
    };

    const outputPath = this.getOutputPath();
    JestJsonReporter.writeOutput(outputPath, outputData);

    console.log(`\n✓ Jest JSON report written to ${outputPath}`);
    console.log(
      `  Tests: ${summary.example_count}, Failures: ${summary.failure_count}, Pending: ${summary.pending_count}, Todo: ${summary.todo_count}`,
    );
  }

  static formatTestCase(testResult, testCaseResult) {
    const formattedTest = {
      id: JestJsonReporter.generateId(testResult, testCaseResult),
      description: testCaseResult.title,
      full_description: testCaseResult.fullName,
      status: testCaseResult.status,
      file_path: JestJsonReporter.relativePath(testResult.testFilePath),
      line_number: testCaseResult.location?.line || 0,
      run_time: (testCaseResult.duration || 0) / 1000,
      pending_message:
        testCaseResult.status === 'pending' ? testCaseResult.failureMessages[0] : null,
      feature_category: null,
      ci_job_url: process.env.CI_JOB_URL || null,
      retry_attempts: testCaseResult.invocations ? testCaseResult.invocations - 1 : 0,
    };

    if (testCaseResult.status === 'failed' && testCaseResult.failureMessages?.length > 0) {
      formattedTest.exceptions = testCaseResult.failureMessages.map((message) => {
        const errorClassMatch = message.match(/^([A-Z]\w+Error):/);
        return {
          class: errorClassMatch ? errorClassMatch[1] : 'Error',
          message,
        };
      });
    }

    return formattedTest;
  }

  static generateId(testResult, testCaseResult) {
    const relativePath = JestJsonReporter.relativePath(testResult.testFilePath);
    return `${relativePath}[${testCaseResult.fullName}]`;
  }

  static relativePath(absolutePath) {
    const cwd = process.cwd();
    const relative = path.relative(cwd, absolutePath);
    return relative.startsWith('./') ? relative.slice(2) : relative;
  }

  getOutputPath() {
    if (this.options.outputPath) {
      return this.options.outputPath;
    }

    const ciJobName = (process.env.CI_JOB_NAME || 'jest').replace(/\s+/g, '-');
    const ciNodeIndex = process.env.CI_NODE_INDEX || '1';
    const outputDir = 'jest-reports';
    const fileName = `${ciJobName}-${ciNodeIndex}.json`;

    return path.join(outputDir, fileName);
  }

  static writeOutput(outputPath, data) {
    const dir = path.dirname(outputPath);

    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    fs.writeFileSync(outputPath, JSON.stringify(data, null, 2), 'utf8');
  }
}

module.exports = JestJsonReporter;
