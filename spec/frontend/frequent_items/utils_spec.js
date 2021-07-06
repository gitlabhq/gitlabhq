import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { HOUR_IN_MS, FREQUENT_ITEMS } from '~/frequent_items/constants';
import {
  isMobile,
  getTopFrequentItems,
  updateExistingFrequentItem,
  sanitizeItem,
} from '~/frequent_items/utils';
import { mockProject, unsortedFrequentItems, sortedFrequentItems } from './mock_data';

describe('Frequent Items utils spec', () => {
  describe('isMobile', () => {
    it('returns true when the screen is medium ', () => {
      jest.spyOn(bp, 'getBreakpointSize').mockReturnValue('md');

      expect(isMobile()).toBe(true);
    });

    it('returns true when the screen is small ', () => {
      jest.spyOn(bp, 'getBreakpointSize').mockReturnValue('sm');

      expect(isMobile()).toBe(true);
    });

    it('returns true when the screen is extra-small ', () => {
      jest.spyOn(bp, 'getBreakpointSize').mockReturnValue('xs');

      expect(isMobile()).toBe(true);
    });

    it('returns false when the screen is larger than medium ', () => {
      jest.spyOn(bp, 'getBreakpointSize').mockReturnValue('lg');

      expect(isMobile()).toBe(false);
    });
  });

  describe('getTopFrequentItems', () => {
    it('returns empty array if no items provided', () => {
      const result = getTopFrequentItems();

      expect(result.length).toBe(0);
    });

    it('returns correct amount of items for mobile', () => {
      jest.spyOn(bp, 'getBreakpointSize').mockReturnValue('md');
      const result = getTopFrequentItems(unsortedFrequentItems);

      expect(result.length).toBe(FREQUENT_ITEMS.LIST_COUNT_MOBILE);
    });

    it('returns correct amount of items for desktop', () => {
      jest.spyOn(bp, 'getBreakpointSize').mockReturnValue('xl');
      const result = getTopFrequentItems(unsortedFrequentItems);

      expect(result.length).toBe(FREQUENT_ITEMS.LIST_COUNT_DESKTOP);
    });

    it('sorts frequent items in order of frequency and lastAccessedOn', () => {
      jest.spyOn(bp, 'getBreakpointSize').mockReturnValue('xl');
      const result = getTopFrequentItems(unsortedFrequentItems);
      const expectedResult = sortedFrequentItems.slice(0, FREQUENT_ITEMS.LIST_COUNT_DESKTOP);

      expect(result).toEqual(expectedResult);
    });
  });

  describe('updateExistingFrequentItem', () => {
    const LAST_ACCESSED = 1497979281815;
    const WITHIN_AN_HOUR = LAST_ACCESSED + HOUR_IN_MS;
    const OVER_AN_HOUR = WITHIN_AN_HOUR + 1;
    const EXISTING_ITEM = Object.freeze({
      ...mockProject,
      frequency: 1,
      lastAccessedOn: 1497979281815,
    });

    it.each`
      desc                                           | existingProps                    | newProps                              | expected
      ${'updates item if accessed over an hour ago'} | ${{}}                            | ${{ lastAccessedOn: OVER_AN_HOUR }}   | ${{ lastAccessedOn: Date.now(), frequency: 2 }}
      ${'does not update is accessed with an hour'}  | ${{}}                            | ${{ lastAccessedOn: WITHIN_AN_HOUR }} | ${{ lastAccessedOn: EXISTING_ITEM.lastAccessedOn, frequency: 1 }}
      ${'updates if lastAccessedOn not found'}       | ${{ lastAccessedOn: undefined }} | ${{ lastAccessedOn: WITHIN_AN_HOUR }} | ${{ lastAccessedOn: Date.now(), frequency: 2 }}
    `('$desc', ({ existingProps, newProps, expected }) => {
      const newItem = {
        ...EXISTING_ITEM,
        ...newProps,
      };
      const existingItem = {
        ...EXISTING_ITEM,
        ...existingProps,
      };

      const result = updateExistingFrequentItem(existingItem, newItem);

      expect(result).toEqual({
        ...newItem,
        ...expected,
      });
    });
  });

  describe('sanitizeItem', () => {
    it('strips HTML tags for name and namespace', () => {
      const input = {
        name: '<br><b>test</b>',
        namespace: '<br>test',
        id: 1,
      };

      expect(sanitizeItem(input)).toEqual({ name: 'test', namespace: 'test', id: 1 });
    });

    it("skips `name` key if it doesn't exist on the item", () => {
      const input = {
        namespace: '<br>test',
        id: 1,
      };

      expect(sanitizeItem(input)).toEqual({ namespace: 'test', id: 1 });
    });

    it("skips `namespace` key if it doesn't exist on the item", () => {
      const input = {
        name: '<br><b>test</b>',
        id: 1,
      };

      expect(sanitizeItem(input)).toEqual({ name: 'test', id: 1 });
    });
  });
});
