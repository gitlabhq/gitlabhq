import { FOUR_MINUTES_IN_MS } from '~/ci/constants';
import { getIncreasedPollInterval } from '~/ci/utils/polling_utils';

describe('Polling utils', () => {
  describe('interval under max limit', () => {
    it('increases the interval', () => {
      expect(getIncreasedPollInterval(1000)).toBe(1000 * 1.2);
      expect(getIncreasedPollInterval(2000)).toBe(2000 * 1.2);
      expect(getIncreasedPollInterval(10000)).toBe(10000 * 1.2);
      expect(getIncreasedPollInterval(200000)).toBe(200000 * 1.2);
    });
  });

  describe('interval over max limit', () => {
    it('returns max interval value', () => {
      expect(getIncreasedPollInterval(300000)).toBe(FOUR_MINUTES_IN_MS);
      expect(getIncreasedPollInterval(400000)).toBe(FOUR_MINUTES_IN_MS);
      expect(getIncreasedPollInterval(500000)).toBe(FOUR_MINUTES_IN_MS);
      expect(getIncreasedPollInterval(600000)).toBe(FOUR_MINUTES_IN_MS);
    });
  });
});
