import AccessorUtilities from '../../lib/utils/accessor';
import { MAX_FREQUENT_ITEMS, MAX_FREQUENCY } from './constants';

function extractKeys(object, keyList) {
  return Object.fromEntries(keyList.map((key) => [key, object[key]]));
}

export const loadDataFromLS = (key) => {
  if (!AccessorUtilities.isLocalStorageAccessSafe()) {
    return [];
  }

  try {
    return JSON.parse(localStorage.getItem(key)) || [];
  } catch {
    // The LS got in a bad state, let's wipe it
    localStorage.removeItem(key);
    return [];
  }
};

export const setFrequentItemToLS = (key, data, itemData) => {
  if (!AccessorUtilities.isLocalStorageAccessSafe()) {
    return;
  }

  const keyList = ['id', 'avatar_url', 'name', 'full_name', 'name_with_namespace', 'frequency'];

  try {
    const frequentItems = data[key].map((obj) => extractKeys(obj, keyList));
    const item = extractKeys(itemData, keyList);
    const existingItemIndex = frequentItems.findIndex((i) => i.id === item.id);

    if (existingItemIndex >= 0) {
      // Up the frequency (Max 5)
      const currentFrequency = frequentItems[existingItemIndex].frequency;
      frequentItems[existingItemIndex].frequency = Math.min(currentFrequency + 1, MAX_FREQUENCY);
    } else {
      // Only store a max of 5 items
      if (frequentItems.length >= MAX_FREQUENT_ITEMS) {
        frequentItems.pop();
      }

      frequentItems.push({ ...item, frequency: 1 });
    }

    // Sort by frequency
    frequentItems.sort((a, b) => b.frequency - a.frequency);

    // Note we do not need to commit a mutation here as immediately after this we refresh the page to
    // update the search results.
    localStorage.setItem(key, JSON.stringify(frequentItems));
  } catch {
    // The LS got in a bad state, let's wipe it
    localStorage.removeItem(key);
  }
};

export const mergeById = (inflatedData, storedData) => {
  return inflatedData.map((data) => {
    const stored = storedData?.find((d) => d.id === data.id) || {};
    return { ...stored, ...data };
  });
};
