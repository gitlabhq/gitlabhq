import MockAdapter from 'axios-mock-adapter';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import {
  getTopFrequentItems,
  trackContextAccess,
  ariaCurrent,
  formatAsyncCount,
} from '~/super_sidebar/utils';
import axios from '~/lib/utils/axios_utils';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import AccessorUtilities from '~/lib/utils/accessor';
import { FREQUENT_ITEMS, FIFTEEN_MINUTES_IN_MS } from '~/super_sidebar/constants';
import { HTTP_STATUS_OK, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import waitForPromises from 'helpers/wait_for_promises';
import { unsortedFrequentItems, sortedFrequentItems } from './mock_data';

jest.mock('~/sentry/sentry_browser_wrapper');

useLocalStorageSpy();

describe('Super sidebar utils spec', () => {
  describe('getTopFrequentItems', () => {
    const maxItems = 3;

    it.each([undefined, null, []])('returns empty array if `items` is %s', (items) => {
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

    let axiosMock;

    const username = 'root';
    const trackVisitsPath = '/-/track_visits';
    const context = {
      namespace: 'groups',
      item: { id: 1 },
    };
    const storageKey = `${username}/frequent-${context.namespace}`;

    beforeEach(() => {
      axiosMock = new MockAdapter(axios);
      axiosMock.onPost(trackVisitsPath).reply(HTTP_STATUS_OK);
    });

    afterEach(() => {
      gon.features = {};
      axiosMock.restore();
    });

    it('returns `false` if local storage is not available', () => {
      jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(false);

      expect(trackContextAccess()).toBe(false);
    });

    it('creates a new item if it does not exist in the local storage', () => {
      trackContextAccess(username, context, trackVisitsPath);

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

    it('sends a POST request to persist the visit in the DB', async () => {
      expect(axiosMock.history.post).toHaveLength(0);

      trackContextAccess(username, context, trackVisitsPath);
      await waitForPromises();

      expect(axiosMock.history.post).toHaveLength(1);
      expect(axiosMock.history.post[0].url).toBe(trackVisitsPath);
    });

    it('logs an error to Sentry when the request fails', async () => {
      axiosMock.onPost(trackVisitsPath).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      trackContextAccess(username, context, trackVisitsPath);
      await waitForPromises();

      expect(Sentry.captureException).toHaveBeenCalled();
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
      trackContextAccess(username, context, trackVisitsPath);

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

    it('leaves item frequency/access time as is if it was persisted to the local storage under 15 minutes ago, and does not send a POST request', () => {
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

      trackContextAccess(username, context, trackVisitsPath);

      expect(window.localStorage.setItem).toHaveBeenCalledTimes(3);
      expect(window.localStorage.setItem).toHaveBeenLastCalledWith(storageKey, jsonString);

      expect(axiosMock.history.post).toHaveLength(0);
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
      trackContextAccess(
        username,
        {
          namespace: 'groups',
          item: newItem,
        },
        trackVisitsPath,
      );
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

  describe('ariaCurrent', () => {
    it.each`
      isActive | expected
      ${true}  | ${'page'}
      ${false} | ${null}
    `('returns `$expected` when `isActive` is `$isActive`', ({ isActive, expected }) => {
      expect(ariaCurrent(isActive)).toBe(expected);
    });
  });

  describe('formatAsyncCount', () => {
    it.each`
      asyncCountValue | result
      ${0}            | ${0}
      ${10}           | ${10}
      ${100234}       | ${'100.2k'}
    `('returns `$result` when count is `$asyncCountValue`', ({ asyncCountValue, result }) => {
      expect(formatAsyncCount(asyncCountValue)).toBe(`${result}`);
    });
  });
});
