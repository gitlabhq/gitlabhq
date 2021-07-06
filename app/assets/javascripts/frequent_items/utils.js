import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { take } from 'lodash';
import { sanitize } from '~/lib/dompurify';
import { FREQUENT_ITEMS, HOUR_IN_MS } from './constants';

export const isMobile = () => ['md', 'sm', 'xs'].includes(bp.getBreakpointSize());

export const getTopFrequentItems = (items) => {
  if (!items) {
    return [];
  }
  const frequentItemsCount = isMobile()
    ? FREQUENT_ITEMS.LIST_COUNT_MOBILE
    : FREQUENT_ITEMS.LIST_COUNT_DESKTOP;

  const frequentItems = items.filter((item) => item.frequency >= FREQUENT_ITEMS.ELIGIBLE_FREQUENCY);

  if (!frequentItems || frequentItems.length === 0) {
    return [];
  }

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

  return take(frequentItems, frequentItemsCount);
};

export const updateExistingFrequentItem = (frequentItem, item) => {
  // `frequentItem` comes from localStorage and it's possible it doesn't have a `lastAccessedOn`
  const neverAccessed = !frequentItem.lastAccessedOn;
  const shouldUpdate =
    neverAccessed || Math.abs(item.lastAccessedOn - frequentItem.lastAccessedOn) / HOUR_IN_MS > 1;

  return {
    ...item,
    frequency: shouldUpdate ? frequentItem.frequency + 1 : frequentItem.frequency,
    lastAccessedOn: shouldUpdate ? Date.now() : frequentItem.lastAccessedOn,
  };
};

export const sanitizeItem = (item) => {
  // Only sanitize if the key exists on the item
  const maybeSanitize = (key) => {
    if (!Object.prototype.hasOwnProperty.call(item, key)) {
      return {};
    }

    return { [key]: sanitize(item[key].toString(), { ALLOWED_TAGS: [] }) };
  };

  return {
    ...item,
    ...maybeSanitize('name'),
    ...maybeSanitize('namespace'),
  };
};
