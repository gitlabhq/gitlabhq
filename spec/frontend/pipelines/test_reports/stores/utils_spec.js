import { formattedTime } from '~/pipelines/stores/test_reports/utils';

describe('Test reports utils', () => {
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
  });
});
