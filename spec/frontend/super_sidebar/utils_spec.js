import * as Sentry from '@sentry/browser';
import {
  getTopFrequentItems,
  trackContextAccess,
  formatContextSwitcherItems,
  getItemsFromLocalStorage,
  removeItemFromLocalStorage,
  ariaCurrent,
} from '~/super_sidebar/utils';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import AccessorUtilities from '~/lib/utils/accessor';
import { FREQUENT_ITEMS, FIFTEEN_MINUTES_IN_MS } from '~/frequent_items/constants';
import { unsortedFrequentItems, sortedFrequentItems } from '../frequent_items/mock_data';
import { cachedFrequentProjects, searchUserProjectsAndGroupsResponseMock } from './mock_data';

jest.mock('@sentry/browser');

useLocalStorageSpy();

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

    it('updates existing item frequency/access time if it was persisted to the local storage over 15 minutes ago', () => {
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

    it('leaves item frequency/access time as is if it was persisted to the local storage under 15 minutes ago', () => {
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

    it('always updates stored item metadata', () => {
      window.localStorage.setItem(
        storageKey,
        JSON.stringify([
          {
            id: 1,
            frequency: 2,
            lastAccessedOn: Date.now(),
          },
        ]),
      );

      trackContextAccess(username, {
        ...context,
        item: {
          ...context.item,
          avatarUrl: '/group.png',
        },
      });

      expect(window.localStorage.setItem).toHaveBeenCalledWith(
        storageKey,
        JSON.stringify([
          {
            id: 1,
            avatarUrl: '/group.png',
            frequency: 2,
            lastAccessedOn: Date.now(),
          },
        ]),
      );
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

  describe('getItemsFromLocalStorage', () => {
    const storageKey = 'mockStorageKey';
    const maxItems = 5;
    const storedItems = JSON.parse(cachedFrequentProjects);

    beforeEach(() => {
      window.localStorage.setItem(storageKey, cachedFrequentProjects);
    });

    describe('when localStorage cannot be accessed', () => {
      beforeEach(() => {
        jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(false);
      });

      it('returns an empty array', () => {
        const items = getItemsFromLocalStorage({ storageKey, maxItems });
        expect(items).toEqual([]);
      });
    });

    describe('when localStorage contains parseable data', () => {
      it('returns an array of items limited by max items', () => {
        const items = getItemsFromLocalStorage({ storageKey, maxItems });
        expect(items.length).toEqual(maxItems);

        items.forEach((item) => {
          expect(storedItems).toContainEqual(item);
        });
      });

      it('returns all items if max items is large', () => {
        const items = getItemsFromLocalStorage({ storageKey, maxItems: 1 });
        expect(items.length).toEqual(1);

        expect(storedItems).toContainEqual(items[0]);
      });
    });

    describe('when localStorage contains unparseable data', () => {
      let items;

      beforeEach(() => {
        window.localStorage.setItem(storageKey, 'unparseable');
        items = getItemsFromLocalStorage({ storageKey, maxItems });
      });

      it('logs an error to Sentry', () => {
        expect(Sentry.captureException).toHaveBeenCalled();
      });

      it('returns an empty array', () => {
        expect(items).toEqual([]);
      });
    });
  });

  describe('removeItemFromLocalStorage', () => {
    const storageKey = 'mockStorageKey';
    const originalStoredItems = JSON.parse(cachedFrequentProjects);

    beforeEach(() => {
      window.localStorage.setItem(storageKey, cachedFrequentProjects);
    });

    describe('when given an item to delete', () => {
      let items;
      let modifiedStoredItems;

      beforeEach(() => {
        items = removeItemFromLocalStorage({ storageKey, item: { id: 3 } });
        modifiedStoredItems = JSON.parse(window.localStorage.getItem(storageKey));
      });

      it('removes the item from localStorage', () => {
        expect(modifiedStoredItems.length).toBe(originalStoredItems.length - 1);
        expect(modifiedStoredItems).not.toContainEqual(originalStoredItems[2]);
      });

      it('returns the resulting stored structure', () => {
        expect(items).toEqual(modifiedStoredItems);
      });
    });

    describe('when given an unknown item to delete', () => {
      let items;
      let modifiedStoredItems;

      beforeEach(() => {
        items = removeItemFromLocalStorage({ storageKey, item: { id: 'does-not-exist' } });
        modifiedStoredItems = JSON.parse(window.localStorage.getItem(storageKey));
      });

      it('does not change the stored value', () => {
        expect(modifiedStoredItems).toEqual(originalStoredItems);
      });

      it('returns the stored structure', () => {
        expect(items).toEqual(originalStoredItems);
      });
    });

    describe('when localStorage has unparseable data', () => {
      let items;

      beforeEach(() => {
        window.localStorage.setItem(storageKey, 'unparseable');
        items = removeItemFromLocalStorage({ storageKey, item: { id: 3 } });
      });

      it('logs an error to Sentry', () => {
        expect(Sentry.captureException).toHaveBeenCalled();
      });

      it('returns an empty array', () => {
        expect(items).toEqual([]);
      });
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
