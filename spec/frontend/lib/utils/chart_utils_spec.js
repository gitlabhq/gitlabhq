import { firstAndLastY } from '~/lib/utils/chart_utils';

describe('Chart utils', () => {
  describe('firstAndLastY', () => {
    it('returns the first and last y-values of a given data set as an array', () => {
      const data = [
        ['', 1],
        ['', 2],
        ['', 3],
      ];

      expect(firstAndLastY(data)).toEqual([1, 3]);
    });
  });
});
