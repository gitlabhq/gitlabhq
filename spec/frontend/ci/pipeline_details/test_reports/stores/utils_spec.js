import { formatFilePath, formattedTime } from '~/ci/pipeline_details/stores/test_reports/utils';

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
  });
});
