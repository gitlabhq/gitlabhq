import AccessorUtilities from '~/lib/utils/accessor';
import { FREQUENT_ITEMS, FIFTEEN_MINUTES_IN_MS } from '~/frequent_items/constants';
import { truncateNamespace } from '~/lib/utils/text_utility';

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
    } else if (itemA.lastAccessedOn !== itemB.lastAccessedOn) {
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

const updateItemAccess = (item) => {
  const now = Date.now();
  const neverAccessed = !item.lastAccessedOn;
  const shouldUpdate =
    neverAccessed || Math.abs(now - item.lastAccessedOn) / FIFTEEN_MINUTES_IN_MS > 1;
  const currentFrequency = item.frequency ?? 0;

  return {
    ...item,
    frequency: shouldUpdate ? currentFrequency + 1 : currentFrequency,
    lastAccessedOn: shouldUpdate ? now : item.lastAccessedOn,
  };
};

export const trackContextAccess = (username, context) => {
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
    storedItems[existingItemIndex] = updateItemAccess(storedItems[existingItemIndex]);
  } else {
    const newItem = updateItemAccess(context.item);
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

export const ariaCurrent = (isActive) => (isActive ? 'page' : null);
