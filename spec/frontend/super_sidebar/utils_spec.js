import { getTopFrequentItems } from '~/super_sidebar/utils';
import { unsortedFrequentItems, sortedFrequentItems } from '../frequent_items/mock_data';

describe('Super sidebar utils spec', () => {
  describe('getTopFrequentItems', () => {
    const maxItems = 3;

    it('returns empty array if no items provided', () => {
      const result = getTopFrequentItems();

      expect(result.length).toBe(0);
    });

    it('returns the requested amount of items', () => {
      const result = getTopFrequentItems(unsortedFrequentItems, maxItems);

      expect(result.length).toBe(maxItems);
    });

    it('sorts frequent items in order of frequency and lastAccessedOn', () => {
      const result = getTopFrequentItems(unsortedFrequentItems, maxItems);
      const expectedResult = sortedFrequentItems.slice(0, maxItems);

      expect(result).toEqual(expectedResult);
    });
  });
});
