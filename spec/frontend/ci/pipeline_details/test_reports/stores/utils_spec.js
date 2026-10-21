import {
  formatFilePath,
  formattedTime,
  addIconStatus,
  filterTestCases,
  iconForTestStatus,
} from '~/ci/pipeline_details/stores/test_reports/utils';
import { testStatus } from '~/ci/pipeline_details/constants';

describe('Test reports utils', () => {
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
      expect(formatFilePath(file)).toBe(expected);
    });
  });

  describe('formattedTime', () => {
    describe('when time is smaller than a second', () => {
      it('should return time in milliseconds fixed to 2 decimals', () => {
        const result = formattedTime(0.4815162342);
        expect(result).toBe('481.52ms');
      });
    });

    describe('when time is equal to a second', () => {
      it('should return time in seconds fixed to 2 decimals', () => {
        const result = formattedTime(1);
        expect(result).toBe('1.00s');
      });
    });

    describe('when time is greater than a second', () => {
      it('should return time in seconds fixed to 2 decimals', () => {
        const result = formattedTime(4.815162342);
        expect(result).toBe('4.82s');
      });
    });

    describe('when time is greater than a minute', () => {
      it('should return time in minutes', () => {
        const result = formattedTime(99);
        expect(result).toBe('1m 39s');
      });
    });

    describe('when time is greater than a hour', () => {
      it('should return time in hours', () => {
        const result = formattedTime(3606);
        expect(result).toBe('1h 6s');
      });
    });

    describe('when time is exact a hour', () => {
      it('should return time as one hour', () => {
        const result = formattedTime(3600);
        expect(result).toBe('1h');
      });
    });

    describe('when time is greater than a hour with some minutes', () => {
      it('should return time in hours', () => {
        const result = formattedTime(3662);
        expect(result).toBe('1h 1m 2s');
      });
    });

    describe('when time is greater than 8 hours', () => {
      it('should return time in hours', () => {
        const result = formattedTime(28801);
        expect(result).toBe('8h 1s');
      });
    });

    describe('when time is greater than 24 hours', () => {
      it('should return time in days', () => {
        const result = formattedTime(86600);
        expect(result).toBe('1d 3m 20s');
      });
    });
  });

  describe('addIconStatus', () => {
    it('should add icon and formattedTime to a test case', () => {
      const testCase = { status: testStatus.SUCCESS, execution_time: 1 };

      expect(addIconStatus(testCase)).toEqual({
        ...testCase,
        icon: iconForTestStatus(testStatus.SUCCESS),
        formattedTime: formattedTime(1),
      });
    });
  });

  describe('filterTestCases', () => {
    const testCases = [
      { classname: 'FooSuite', name: 'renders correctly' },
      { classname: 'BarSuite', name: 'handles errors' },
    ];

    describe('when the search term is empty', () => {
      it('returns all test cases', () => {
        expect(filterTestCases(testCases, '')).toEqual(testCases);
      });
    });

    describe('when searching by classname', () => {
      it('matches case-insensitively', () => {
        expect(filterTestCases(testCases, 'foosuite')).toEqual([testCases[0]]);
      });
    });

    describe('when searching by name', () => {
      it('matches case-insensitively', () => {
        expect(filterTestCases(testCases, 'ERRORS')).toEqual([testCases[1]]);
      });
    });

    describe('when nothing matches', () => {
      it('returns an empty array', () => {
        expect(filterTestCases(testCases, 'nope')).toEqual([]);
      });
    });
  });
});
