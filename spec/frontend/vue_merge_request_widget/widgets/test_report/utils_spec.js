import * as utils from '~/vue_merge_request_widget/widgets/test_report/utils';

describe('test report widget extension utils', () => {
  describe('summaryTextbuilder', () => {
    it('should render text for no changed results in multiple tests', () => {
      const name = 'Test summary';
      const data = { total: 10 };
      const result = utils.summaryTextBuilder(name, data);

      expect(result).toBe(
        'Test summary: %{strong_start}no%{strong_end} changed test results, %{strong_start}10%{strong_end} total tests',
      );
    });

    it('should render text for no changed results in one test', () => {
      const name = 'Test summary';
      const data = { total: 1 };
      const result = utils.summaryTextBuilder(name, data);

      expect(result).toBe(
        'Test summary: %{strong_start}no%{strong_end} changed test results, %{strong_start}1%{strong_end} total test',
      );
    });

    it('should render text for multiple failed results', () => {
      const name = 'Test summary';
      const data = { failed: 3, total: 10 };
      const result = utils.summaryTextBuilder(name, data);

      expect(result).toBe(
        'Test summary: %{strong_start}3%{strong_end} failed, %{strong_start}10%{strong_end} total tests',
      );
    });

    it('should render text for multiple errored results', () => {
      const name = 'Test summary';
      const data = { errored: 7, total: 10 };
      const result = utils.summaryTextBuilder(name, data);

      expect(result).toBe(
        'Test summary: %{strong_start}7%{strong_end} errors, %{strong_start}10%{strong_end} total tests',
      );
    });

    it('should render text for multiple fixed results', () => {
      const name = 'Test summary';
      const data = { resolved: 4, total: 10 };
      const result = utils.summaryTextBuilder(name, data);

      expect(result).toBe(
        'Test summary: %{strong_start}4%{strong_end} fixed test results, %{strong_start}10%{strong_end} total tests',
      );
    });

    it('should render text for multiple fixed, and multiple failed results', () => {
      const name = 'Test summary';
      const data = { failed: 3, resolved: 4, total: 10 };
      const result = utils.summaryTextBuilder(name, data);

      expect(result).toBe(
        'Test summary: %{strong_start}3%{strong_end} failed and %{strong_start}4%{strong_end} fixed test results, %{strong_start}10%{strong_end} total tests',
      );
    });

    it('should render text for a singular fixed, and a singular failed result', () => {
      const name = 'Test summary';
      const data = { failed: 1, resolved: 1, total: 10 };
      const result = utils.summaryTextBuilder(name, data);

      expect(result).toBe(
        'Test summary: %{strong_start}1%{strong_end} failed and %{strong_start}1%{strong_end} fixed test result, %{strong_start}10%{strong_end} total tests',
      );
    });

    it('should render text for singular failed, errored, and fixed results', () => {
      const name = 'Test summary';
      const data = { failed: 1, errored: 1, resolved: 1, total: 10 };
      const result = utils.summaryTextBuilder(name, data);

      expect(result).toBe(
        'Test summary: %{strong_start}1%{strong_end} failed, %{strong_start}1%{strong_end} error and %{strong_start}1%{strong_end} fixed test result, %{strong_start}10%{strong_end} total tests',
      );
    });

    it('should render text for multiple failed, errored, and fixed results', () => {
      const name = 'Test summary';
      const data = { failed: 2, errored: 3, resolved: 4, total: 10 };
      const result = utils.summaryTextBuilder(name, data);

      expect(result).toBe(
        'Test summary: %{strong_start}2%{strong_end} failed, %{strong_start}3%{strong_end} errors and %{strong_start}4%{strong_end} fixed test results, %{strong_start}10%{strong_end} total tests',
      );
    });
  });

  describe('reportTextBuilder', () => {
    const name = 'Rspec';

    it('should render text for no changed results in multiple tests', () => {
      const data = { name, summary: { total: 10 } };
      const result = utils.reportTextBuilder(data);

      expect(result).toBe('Rspec: no changed test results, 10 total tests');
    });

    it('should render text for no changed results in one test', () => {
      const data = { name, summary: { total: 1 } };
      const result = utils.reportTextBuilder(data);

      expect(result).toBe('Rspec: no changed test results, 1 total test');
    });

    it('should render text for multiple failed results', () => {
      const data = { name, summary: { failed: 3, total: 10 } };
      const result = utils.reportTextBuilder(data);

      expect(result).toBe('Rspec: 3 failed, 10 total tests');
    });

    it('should render text for multiple errored results', () => {
      const data = { name, summary: { errored: 7, total: 10 } };
      const result = utils.reportTextBuilder(data);

      expect(result).toBe('Rspec: 7 errors, 10 total tests');
    });

    it('should render text for multiple fixed results', () => {
      const data = { name, summary: { resolved: 4, total: 10 } };
      const result = utils.reportTextBuilder(data);

      expect(result).toBe('Rspec: 4 fixed test results, 10 total tests');
    });

    it('should render text for multiple fixed, and multiple failed results', () => {
      const data = { name, summary: { failed: 3, resolved: 4, total: 10 } };
      const result = utils.reportTextBuilder(data);

      expect(result).toBe('Rspec: 3 failed and 4 fixed test results, 10 total tests');
    });

    it('should render text for a singular fixed, and a singular failed result', () => {
      const data = { name, summary: { failed: 1, resolved: 1, total: 10 } };
      const result = utils.reportTextBuilder(data);

      expect(result).toBe('Rspec: 1 failed and 1 fixed test result, 10 total tests');
    });

    it('should render text for singular failed, errored, and fixed results', () => {
      const data = { name, summary: { failed: 1, errored: 1, resolved: 1, total: 10 } };
      const result = utils.reportTextBuilder(data);

      expect(result).toBe('Rspec: 1 failed, 1 error and 1 fixed test result, 10 total tests');
    });

    it('should render text for multiple failed, errored, and fixed results', () => {
      const data = { name, summary: { failed: 2, errored: 3, resolved: 4, total: 10 } };
      const result = utils.reportTextBuilder(data);

      expect(result).toBe('Rspec: 2 failed, 3 errors and 4 fixed test results, 10 total tests');
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

    it.each([
      [],
      {},
      null,
      undefined,
      { new_failures: undefined },
      [{ existing_failures: null }],
      { resolved_failures: [{}] },
      [{ new_failures: [{ recent_failures: {} }] }],
    ])('returns 0 when subject is %s', (subject) => {
      const result = utils.countRecentlyFailedTests(subject);

      expect(result).toBe(0);
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
