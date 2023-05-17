import {
  getTopFrequentItems,
  trackContextAccess,
  formatContextSwitcherItems,
  ariaCurrent,
} from '~/super_sidebar/utils';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import AccessorUtilities from '~/lib/utils/accessor';
import { FREQUENT_ITEMS, FIFTEEN_MINUTES_IN_MS } from '~/frequent_items/constants';
import { unsortedFrequentItems, sortedFrequentItems } from '../frequent_items/mock_data';
import { searchUserProjectsAndGroupsResponseMock } from './mock_data';

describe('Super sidebar utils spec', () => {
  describe('getTopFrequentItems', () => {
    const maxItems = 3;

    it.each([undefined, null])('returns empty array if `items` is %s', (items) => {
      const result = getTopFrequentItems(items);

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

  describe('trackContextAccess', () => {
    useLocalStorageSpy();

    const username = 'root';
    const context = {
      namespace: 'groups',
      item: { id: 1 },
    };
    const storageKey = `${username}/frequent-${context.namespace}`;

    it('returns `false` if local storage is not available', () => {
      jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(false);

      expect(trackContextAccess()).toBe(false);
    });

    it('creates a new item if it does not exist in the local storage', () => {
      trackContextAccess(username, context);

      expect(window.localStorage.setItem).toHaveBeenCalledWith(
        storageKey,
        JSON.stringify([
          {
            id: 1,
            frequency: 1,
            lastAccessedOn: Date.now(),
          },
        ]),
      );
    });

    it('updates existing item if it was persisted to the local storage over 15 minutes ago', () => {
      window.localStorage.setItem(
        storageKey,
        JSON.stringify([
          {
            id: 1,
            frequency: 2,
            lastAccessedOn: Date.now() - FIFTEEN_MINUTES_IN_MS - 1,
          },
        ]),
      );
      trackContextAccess(username, context);

      expect(window.localStorage.setItem).toHaveBeenCalledWith(
        storageKey,
        JSON.stringify([
          {
            id: 1,
            frequency: 3,
            lastAccessedOn: Date.now(),
          },
        ]),
      );
    });

    it('leaves item as is if it was persisted to the local storage under 15 minutes ago', () => {
      const jsonString = JSON.stringify([
        {
          id: 1,
          frequency: 2,
          lastAccessedOn: Date.now() - FIFTEEN_MINUTES_IN_MS,
        },
      ]);
      window.localStorage.setItem(storageKey, jsonString);

      expect(window.localStorage.setItem).toHaveBeenCalledTimes(1);
      expect(window.localStorage.setItem).toHaveBeenCalledWith(storageKey, jsonString);

      trackContextAccess(username, context);

      expect(window.localStorage.setItem).toHaveBeenCalledTimes(3);
      expect(window.localStorage.setItem).toHaveBeenLastCalledWith(storageKey, jsonString);
    });

    it('replaces the least popular item in the local storage once the persisted items limit has been hit', () => {
      // Add the maximum amount of items to the local storage, in increasing popularity
      const storedItems = Array.from({ length: FREQUENT_ITEMS.MAX_COUNT }).map((_, i) => ({
        id: i + 1,
        frequency: i + 1,
        lastAccessedOn: Date.now(),
      }));
      // The first item is considered the least popular one as it has the lowest frequency (1)
      const [leastPopularItem] = storedItems;
      // Persist the list to the local storage
      const jsonString = JSON.stringify(storedItems);
      window.localStorage.setItem(storageKey, jsonString);
      // Track some new item that hasn't been visited yet
      const newItem = {
        id: FREQUENT_ITEMS.MAX_COUNT + 1,
      };
      trackContextAccess(username, {
        namespace: 'groups',
        item: newItem,
      });
      // Finally, retrieve the final data from the local storage
      const finallyStoredItems = JSON.parse(window.localStorage.getItem(storageKey));

      expect(finallyStoredItems).not.toEqual(expect.arrayContaining([leastPopularItem]));
      expect(finallyStoredItems).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            id: newItem.id,
            frequency: 1,
          }),
        ]),
      );
    });
  });

  describe('formatContextSwitcherItems', () => {
    it('returns the formatted items', () => {
      const projects = searchUserProjectsAndGroupsResponseMock.data.projects.nodes;
      expect(formatContextSwitcherItems(projects)).toEqual([
        {
          id: projects[0].id,
          avatar: null,
          title: projects[0].name,
          subtitle: 'Gitlab Org',
          link: projects[0].webUrl,
        },
      ]);
    });
  });

  describe('ariaCurrent', () => {
    it.each`
      isActive | expected
      ${true}  | ${'page'}
      ${false} | ${null}
    `('returns `$expected` when `isActive` is `$isActive`', ({ isActive, expected }) => {
      expect(ariaCurrent(isActive)).toBe(expected);
    });
  });
});
