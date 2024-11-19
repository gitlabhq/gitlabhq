import * as Sentry from '~/sentry/sentry_browser_wrapper';
import AccessorUtilities from '~/lib/utils/accessor';
import { FREQUENT_ITEMS, FIFTEEN_MINUTES_IN_MS } from '~/super_sidebar/constants';
import axios from '~/lib/utils/axios_utils';
import { numberToMetricPrefix } from '~/lib/utils/number_utils';

/**
 * This takes an array of project or groups that were stored in the local storage, to be shown in
 * the context switcher, and sorts them by frequency and last access date.
 * In the resulting array, the most popular item (highest frequency and most recent access date) is
 * placed at the first index, while the least popular is at the last index.
 *
 * @param {Array} items The projects or groups stored in the local storage
 * @returns The items, sorted by frequency and last access date
 */
const sortItemsByFrequencyAndLastAccess = (items) =>
  items.sort((itemA, itemB) => {
    // Sort all frequent items in decending order of frequency
    // and then by lastAccessedOn with recent most first
    if (itemA.frequency !== itemB.frequency) {
      return itemB.frequency - itemA.frequency;
    }
    if (itemA.lastAccessedOn !== itemB.lastAccessedOn) {
      return itemB.lastAccessedOn - itemA.lastAccessedOn;
    }

    return 0;
  });

/**
 * Returns the most frequently visited items.
 *
 * @param {Array} items - A list of items retrieved from the local storage
 * @param {Number} maxCount - The maximum number of items to be returned
 * @returns {Array}
 */
export const getTopFrequentItems = (items, maxCount) => {
  if (!Array.isArray(items)) return [];

  const frequentItems = items.filter((item) => item.frequency >= FREQUENT_ITEMS.ELIGIBLE_FREQUENCY);
  sortItemsByFrequencyAndLastAccess(frequentItems);

  return frequentItems.slice(0, maxCount);
};

/**
 * This tracks projects' and groups' visits in order to suggest a list of frequently visited
 * entities to the user. The suggestion logic is implemented server-side and computed items can be
 * retrieved through the GraphQL API.
 * To persist a visit in the DB, an AJAX request needs to be triggered by the client. To avoid making
 * the request on every visited page, we also keep track of the visits in the local storage so that
 * the request is only sent once every 15 minutes per namespace per user.
 *
 * @param {object} item The project/group item being tracked.
 * @param {string} namespace A string indicating whether the tracked entity is a project or a group.
 * @param {string} trackVisitsPath The API endpoint to track visits server-side.
 * @returns {void}
 */
const updateItemAccess = (
  contextItem,
  { lastAccessedOn, frequency = 0 } = {},
  namespace,
  trackVisitsPath,
  // eslint-disable-next-line max-params
) => {
  const now = Date.now();
  const neverAccessed = !lastAccessedOn;
  const shouldUpdate = neverAccessed || Math.abs(now - lastAccessedOn) / FIFTEEN_MINUTES_IN_MS > 1;

  if (shouldUpdate) {
    axios({
      url: trackVisitsPath,
      method: 'POST',
      data: {
        type: namespace,
        id: contextItem.id,
      },
    }).catch((e) => {
      Sentry.captureException(e);
    });
  }

  return {
    ...contextItem,
    frequency: shouldUpdate ? frequency + 1 : frequency,
    lastAccessedOn: shouldUpdate ? now : lastAccessedOn,
  };
};

export const trackContextAccess = (username, context, trackVisitsPath) => {
  if (!AccessorUtilities.canUseLocalStorage()) {
    return false;
  }

  const storageKey = `${username}/frequent-${context.namespace}`;
  const storedRawItems = localStorage.getItem(storageKey);
  const storedItems = storedRawItems ? JSON.parse(storedRawItems) : [];
  const existingItemIndex = storedItems.findIndex(
    (cachedItem) => cachedItem.id === context.item.id,
  );

  if (existingItemIndex > -1) {
    storedItems[existingItemIndex] = updateItemAccess(
      context.item,
      storedItems[existingItemIndex],
      context.namespace,
      trackVisitsPath,
    );
  } else {
    const newItem = updateItemAccess(
      context.item,
      storedItems[existingItemIndex],
      context.namespace,
      trackVisitsPath,
    );
    if (storedItems.length === FREQUENT_ITEMS.MAX_COUNT) {
      sortItemsByFrequencyAndLastAccess(storedItems);
      storedItems.pop();
    }
    storedItems.push(newItem);
  }

  return localStorage.setItem(storageKey, JSON.stringify(storedItems));
};

export const ariaCurrent = (isActive) => (isActive ? 'page' : null);

const isValidNumber = (count) => {
  return typeof count === 'number';
};

export const formatAsyncCount = (count) => {
  return isValidNumber(count) ? numberToMetricPrefix(count) : null;
};
