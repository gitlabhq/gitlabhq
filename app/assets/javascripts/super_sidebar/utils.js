import { FREQUENT_ITEMS } from '~/frequent_items/constants';

// This imitates getTopFrequentItems from app/assets/javascripts/frequent_items/utils.js, but
// adjusts the rules to accommodate for the context switcher's designs.
export const getTopFrequentItems = (items = [], maxCount) => {
  const frequentItems = items.filter((item) => item.frequency >= FREQUENT_ITEMS.ELIGIBLE_FREQUENCY);

  frequentItems.sort((itemA, itemB) => {
    // Sort all frequent items in decending order of frequency
    // and then by lastAccessedOn with recent most first
    if (itemA.frequency !== itemB.frequency) {
      return itemB.frequency - itemA.frequency;
    } else if (itemA.lastAccessedOn !== itemB.lastAccessedOn) {
      return itemB.lastAccessedOn - itemA.lastAccessedOn;
    }

    return 0;
  });

  return frequentItems.slice(0, maxCount);
};
