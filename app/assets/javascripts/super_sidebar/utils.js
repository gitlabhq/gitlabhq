import * as Sentry from '@sentry/browser';
import AccessorUtilities from '~/lib/utils/accessor';
import { FREQUENT_ITEMS, FIFTEEN_MINUTES_IN_MS } from '~/frequent_items/constants';
import { truncateNamespace } from '~/lib/utils/text_utility';
import axios from '~/lib/utils/axios_utils';

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

// This imitates getTopFrequentItems from app/assets/javascripts/frequent_items/utils.js, but
// adjusts the rules to accommodate for the context switcher's designs.
export const getTopFrequentItems = (items, maxCount) => {
  if (!Array.isArray(items)) return [];

  const frequentItems = items.filter((item) => item.frequency >= FREQUENT_ITEMS.ELIGIBLE_FREQUENCY);
  sortItemsByFrequencyAndLastAccess(frequentItems);

  return frequentItems.slice(0, maxCount);
};

/**
 * This tracks projects' and groups' visits in order to suggest a list of frequently visited
 * entities to the user. Currently, this track visits in two ways:
 * - The legacy approach uses a simple counting algorithm and stores the data in the local storage.
 * - The above approach is being migrated to a backend-based one, where visits will be stored in the
 *   DB, and suggestions will be made through a smarter algorithm. When we are ready to transition
 *   to the newer approach, the legacy one will be cleaned up.
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
) => {
  const now = Date.now();
  const neverAccessed = !lastAccessedOn;
  const shouldUpdate = neverAccessed || Math.abs(now - lastAccessedOn) / FIFTEEN_MINUTES_IN_MS > 1;

  if (shouldUpdate && gon.features?.serverSideFrecentNamespaces) {
    try {
      axios({
        url: trackVisitsPath,
        method: 'POST',
        data: {
          type: namespace,
          id: contextItem.id,
        },
      });
    } catch (e) {
      Sentry.captureException(e);
    }
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

export const formatContextSwitcherItems = (items) =>
  items.map(({ id, name: title, namespace, avatarUrl: avatar, webUrl: link }) => ({
    id,
    title,
    subtitle: truncateNamespace(namespace),
    avatar,
    link,
  }));

export const getItemsFromLocalStorage = ({ storageKey, maxItems }) => {
  if (!AccessorUtilities.canUseLocalStorage()) {
    return [];
  }

  try {
    const parsedCachedFrequentItems = JSON.parse(localStorage.getItem(storageKey));
    return getTopFrequentItems(parsedCachedFrequentItems, maxItems);
  } catch (e) {
    Sentry.captureException(e);
    return [];
  }
};

export const removeItemFromLocalStorage = ({ storageKey, item }) => {
  try {
    const parsedCachedFrequentItems = JSON.parse(localStorage.getItem(storageKey));
    const filteredItems = parsedCachedFrequentItems.filter((i) => i.id !== item.id);
    localStorage.setItem(storageKey, JSON.stringify(filteredItems));

    return filteredItems;
  } catch (e) {
    Sentry.captureException(e);
    return [];
  }
};

export const ariaCurrent = (isActive) => (isActive ? 'page' : null);
