/* eslint-disable no-console */

class SelfCheckReporter {
  constructor() {
    this.failedChecks = [];
  }

  onTestResult(contexts, results) {
    results.testResults.forEach(result => {
      const [rootName, suiteName] = result.ancestorTitles;
      const checkName = result.fullName.replace(`${rootName} ${suiteName} `, '');
      const hasCheckPassed = suiteName === `expected status: ${result.status}`;
      if (hasCheckPassed) {
        console.log(`✓ ${checkName}`);
      } else {
        this.failedChecks.push(checkName);
      }
    });
  }

  getLastError() {
    if (this.failedChecks.length > 0) {
      throw new Error(['The following checks have failed:', ...this.failedChecks].join('\n* '));
    } else {
      process.exit(0);
    }
  }
}

// eslint-disable-next-line import/no-commonjs
module.exports = SelfCheckReporter;
