import {
  STATUS_FAILED,
  STATUS_SUCCESS,
  ICON_WARNING,
  ICON_SUCCESS,
  ICON_NOTFOUND,
} from '~/reports/constants';
import * as utils from '~/reports/grouped_test_report/store/utils';

describe('Reports store utils', () => {
  describe('summaryTextbuilder', () => {
    it('should render text for no changed results in multiple tests', () => {
      const name = 'Test summary';
      const data = { total: 10 };
      const result = utils.summaryTextBuilder(name, data);

      expect(result).toBe('Test summary contained no changed test results out of 10 total tests');
    });

    it('should render text for no changed results in one test', () => {
      const name = 'Test summary';
      const data = { total: 1 };
      const result = utils.summaryTextBuilder(name, data);

      expect(result).toBe('Test summary contained no changed test results out of 1 total test');
    });

    it('should render text for multiple failed results', () => {
      const name = 'Test summary';
      const data = { failed: 3, total: 10 };
      const result = utils.summaryTextBuilder(name, data);

      expect(result).toBe('Test summary contained 3 failed out of 10 total tests');
    });

    it('should render text for multiple errored results', () => {
      const name = 'Test summary';
      const data = { errored: 7, total: 10 };
      const result = utils.summaryTextBuilder(name, data);

      expect(result).toBe('Test summary contained 7 errors out of 10 total tests');
    });

    it('should render text for multiple fixed results', () => {
      const name = 'Test summary';
      const data = { resolved: 4, total: 10 };
      const result = utils.summaryTextBuilder(name, data);

      expect(result).toBe('Test summary contained 4 fixed test results out of 10 total tests');
    });

    it('should render text for multiple fixed, and multiple failed results', () => {
      const name = 'Test summary';
      const data = { failed: 3, resolved: 4, total: 10 };
      const result = utils.summaryTextBuilder(name, data);

      expect(result).toBe(
        'Test summary contained 3 failed and 4 fixed test results out of 10 total tests',
      );
    });

    it('should render text for a singular fixed, and a singular failed result', () => {
      const name = 'Test summary';
      const data = { failed: 1, resolved: 1, total: 10 };
      const result = utils.summaryTextBuilder(name, data);

      expect(result).toBe(
        'Test summary contained 1 failed and 1 fixed test result out of 10 total tests',
      );
    });

    it('should render text for singular failed, errored, and fixed results', () => {
      const name = 'Test summary';
      const data = { failed: 1, errored: 1, resolved: 1, total: 10 };
      const result = utils.summaryTextBuilder(name, data);

      expect(result).toBe(
        'Test summary contained 1 failed, 1 error and 1 fixed test result out of 10 total tests',
      );
    });

    it('should render text for multiple failed, errored, and fixed results', () => {
      const name = 'Test summary';
      const data = { failed: 2, errored: 3, resolved: 4, total: 10 };
      const result = utils.summaryTextBuilder(name, data);

      expect(result).toBe(
        'Test summary contained 2 failed, 3 errors and 4 fixed test results out of 10 total tests',
      );
    });
  });

  describe('reportTextBuilder', () => {
    it('should render text for no changed results in multiple tests', () => {
      const name = 'Rspec';
      const data = { total: 10 };
      const result = utils.reportTextBuilder(name, data);

      expect(result).toBe('Rspec found no changed test results out of 10 total tests');
    });

    it('should render text for no changed results in one test', () => {
      const name = 'Rspec';
      const data = { total: 1 };
      const result = utils.reportTextBuilder(name, data);

      expect(result).toBe('Rspec found no changed test results out of 1 total test');
    });

    it('should render text for multiple failed results', () => {
      const name = 'Rspec';
      const data = { failed: 3, total: 10 };
      const result = utils.reportTextBuilder(name, data);

      expect(result).toBe('Rspec found 3 failed out of 10 total tests');
    });

    it('should render text for multiple errored results', () => {
      const name = 'Rspec';
      const data = { errored: 7, total: 10 };
      const result = utils.reportTextBuilder(name, data);

      expect(result).toBe('Rspec found 7 errors out of 10 total tests');
    });

    it('should render text for multiple fixed results', () => {
      const name = 'Rspec';
      const data = { resolved: 4, total: 10 };
      const result = utils.reportTextBuilder(name, data);

      expect(result).toBe('Rspec found 4 fixed test results out of 10 total tests');
    });

    it('should render text for multiple fixed, and multiple failed results', () => {
      const name = 'Rspec';
      const data = { failed: 3, resolved: 4, total: 10 };
      const result = utils.reportTextBuilder(name, data);

      expect(result).toBe('Rspec found 3 failed and 4 fixed test results out of 10 total tests');
    });

    it('should render text for a singular fixed, and a singular failed result', () => {
      const name = 'Rspec';
      const data = { failed: 1, resolved: 1, total: 10 };
      const result = utils.reportTextBuilder(name, data);

      expect(result).toBe('Rspec found 1 failed and 1 fixed test result out of 10 total tests');
    });

    it('should render text for singular failed, errored, and fixed results', () => {
      const name = 'Rspec';
      const data = { failed: 1, errored: 1, resolved: 1, total: 10 };
      const result = utils.reportTextBuilder(name, data);

      expect(result).toBe(
        'Rspec found 1 failed, 1 error and 1 fixed test result out of 10 total tests',
      );
    });

    it('should render text for multiple failed, errored, and fixed results', () => {
      const name = 'Rspec';
      const data = { failed: 2, errored: 3, resolved: 4, total: 10 };
      const result = utils.reportTextBuilder(name, data);

      expect(result).toBe(
        'Rspec found 2 failed, 3 errors and 4 fixed test results out of 10 total tests',
      );
    });
  });

  describe('recentFailuresTextBuilder', () => {
    it.each`
      recentlyFailed | failed | expected
      ${0}           | ${1}   | ${''}
      ${1}           | ${1}   | ${'1 out of 1 failed test has failed more than once in the last 14 days'}
      ${1}           | ${2}   | ${'1 out of 2 failed tests has failed more than once in the last 14 days'}
      ${2}           | ${3}   | ${'2 out of 3 failed tests have failed more than once in the last 14 days'}
    `(
      'should render summary for $recentlyFailed out of $failed failures',
      ({ recentlyFailed, failed, expected }) => {
        const result = utils.recentFailuresTextBuilder({ recentlyFailed, failed });

        expect(result).toBe(expected);
      },
    );
  });

  describe('countRecentlyFailedTests', () => {
    it('counts tests with more than one recent failure in a report', () => {
      const report = {
        new_failures: [{ recent_failures: { count: 2 } }],
        existing_failures: [{ recent_failures: { count: 1 } }],
        resolved_failures: [{ recent_failures: { count: 20 } }, { recent_failures: { count: 5 } }],
      };
      const result = utils.countRecentlyFailedTests(report);

      expect(result).toBe(3);
    });

    it('counts tests  with more than one recent failure in an array of reports', () => {
      const reports = [
        {
          new_failures: [{ recent_failures: { count: 2 } }],
          existing_failures: [
            { recent_failures: { count: 20 } },
            { recent_failures: { count: 5 } },
          ],
          resolved_failures: [{ recent_failures: { count: 2 } }],
        },
        {
          new_failures: [{ recent_failures: { count: 8 } }, { recent_failures: { count: 14 } }],
          existing_failures: [{ recent_failures: { count: 1 } }],
          resolved_failures: [{ recent_failures: { count: 7 } }, { recent_failures: { count: 5 } }],
        },
      ];
      const result = utils.countRecentlyFailedTests(reports);

      expect(result).toBe(8);
    });
  });

  describe('statusIcon', () => {
    describe('with failed status', () => {
      it('returns ICON_WARNING', () => {
        expect(utils.statusIcon(STATUS_FAILED)).toEqual(ICON_WARNING);
      });
    });

    describe('with success status', () => {
      it('returns ICON_SUCCESS', () => {
        expect(utils.statusIcon(STATUS_SUCCESS)).toEqual(ICON_SUCCESS);
      });
    });

    describe('without a status', () => {
      it('returns ICON_NOTFOUND', () => {
        expect(utils.statusIcon()).toEqual(ICON_NOTFOUND);
      });
    });
  });

  describe('formatFilePath', () => {
    it.each`
      file                        | expected
      ${'./test.js'}              | ${'test.js'}
      ${'/test.js'}               | ${'test.js'}
      ${'.//////////////test.js'} | ${'test.js'}
      ${'test.js'}                | ${'test.js'}
      ${'mock/path./test.js'}     | ${'mock/path./test.js'}
      ${'./mock/path./test.js'}   | ${'mock/path./test.js'}
    `('should format $file to be $expected', ({ file, expected }) => {
      expect(utils.formatFilePath(file)).toBe(expected);
    });
  });
});
