import { getTimeRange } from '~/logs/utils';

describe('logs/utils', () => {
  describe('getTimeRange', () => {
    const nowTimestamp = 1577836800000;
    const nowString = '2020-01-01T00:00:00.000Z';

    beforeEach(() => {
      jest.spyOn(Date, 'now').mockImplementation(() => nowTimestamp);
    });

    afterEach(() => {
      Date.now.mockRestore();
    });

    it('returns the right values', () => {
      expect(getTimeRange(0)).toEqual({
        start: '2020-01-01T00:00:00.000Z',
        end: nowString,
      });

      expect(getTimeRange(60 * 30)).toEqual({
        start: '2019-12-31T23:30:00.000Z',
        end: nowString,
      });

      expect(getTimeRange(60 * 60 * 24 * 7 * 1)).toEqual({
        start: '2019-12-25T00:00:00.000Z',
        end: nowString,
      });

      expect(getTimeRange(60 * 60 * 24 * 7 * 4)).toEqual({
        start: '2019-12-04T00:00:00.000Z',
        end: nowString,
      });
    });
  });
});
