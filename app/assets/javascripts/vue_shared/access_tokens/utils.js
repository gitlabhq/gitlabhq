import { cloneDeep, groupBy, isEqual, map, mapValues } from 'lodash-es';
import {
  getDateInFuture,
  getDayDifference,
  nDaysAfter,
  setUTCTime,
  toISODateFormat,
} from '~/lib/utils/datetime_utility';
import { humanize } from '~/lib/utils/text_utility';
import { STATISTICS_CONFIG } from '~/access_tokens/constants';
import { ACCESS_SCOPE_KEYS } from './constants';

/**
 * Return the default expiration date.
 * If the maximum date is sooner than the 30 days we use the maximum date, otherwise default to 30 days.
 * The maximum date can be set by admins only in EE.
 * @param {Date} [maxDate]
 */
export function defaultDate(maxDate) {
  const OFFSET_DAYS = 30;
  const thirtyDaysFromNow = getDateInFuture(new Date(), OFFSET_DAYS);
  if (maxDate && maxDate < thirtyDaysFromNow) {
    return maxDate;
  }
  return thirtyDaysFromNow;
}

/**
 * Return the default expiration date when rotating a token: the token keeps its lifetime,
 * starting today, within the allowed date range.
 * A token without expiration falls back to the creation default when an expiration is required.
 * @param {{createdAt: string, expiresAt: string|null}} token
 * @param {{minDate?: Date|null, maxDate?: Date|null}} [range]
 */
export function rotationDefaultDate({ createdAt, expiresAt }, { minDate, maxDate } = {}) {
  if (!expiresAt) {
    return maxDate ? defaultDate(maxDate) : null;
  }

  const lifetimeInDays = getDayDifference(setUTCTime(createdAt), setUTCTime(expiresAt));
  const date = getDateInFuture(new Date(), lifetimeInDays);

  if (maxDate && date > maxDate) {
    return maxDate;
  }
  if (minDate && date < minDate) {
    return minDate;
  }
  return date;
}

/**
 * Update the URL query, skipping the navigation when the query is unchanged: vue-router rejects
 * a navigation to the current location. Route query values are strings, so ours are compared as such.
 * @param {import('vue-router').default} router
 * @param {Object<string, number|string>} query
 * @param {{replace?: boolean}} [options] use `replace` to avoid adding a history entry
 */
export function navigateToQuery(router, query, { replace = false } = {}) {
  if (isEqual(mapValues(query, String), router.currentRoute.query)) return;

  router[replace ? 'replace' : 'push']({ query });
}

/**
 * Convert filter structure to an object that can be used as query params.
 * @param {import('./stores/access_tokens').Filters} filters
 * @param {number} [page]
 */
export function serializeParams(filters, page = 1) {
  /** @type {Object<string, number|string>} */
  const newParams = { page };

  filters?.forEach((token) => {
    if (typeof token === 'string') {
      newParams.search = token;
    } else if (['created', 'expires', 'last_used'].includes(token.type)) {
      const isBefore = token.value.operator === '<';
      const key = `${token.type}${isBefore ? '_before' : '_after'}`;
      newParams[key] = token.value.data;
    } else {
      newParams[token.type] = token.value.data;
    }
  });

  return newParams;
}

/**
 * Returns a date 15 days in the future based on current time in ISO format ('YYYY-MM-DD')
 */
export function fifteenDaysFromNow() {
  return toISODateFormat(nDaysAfter(new Date(), 15));
}

/**
 * Replace the 'DATE_HOLDER' string with a date 15 days in the future based on current time.
 */
export function update15DaysFromNow(stats = STATISTICS_CONFIG) {
  const clonedStats = cloneDeep(stats);
  clonedStats.forEach((stat) => {
    const filter = stat.filters.find((item) => item.value.data === 'DATE_HOLDER');
    if (filter) {
      filter.value.data = fifteenDaysFromNow();
    }
  });

  return clonedStats;
}

/**
 * Transform any datetime to T00:00:00.000Z UTC time: '2025-10-13T19:56:59.460Z' -> '2025-10-13T00:00:00.000Z'
 *
 * @param {string} isoDateTimeString - The ISO date string: '2025-10-13T19:56:59.460Z'
 */
export function resetCreatedTime(isoDateTimeString) {
  return setUTCTime(isoDateTimeString).toISOString();
}

/**
 * Interpret the date as UTC time: 2025-10-13 -> 2025-10-13T00:00:00.000Z
 *
 * @param {string} isoDateString - The ISO date string: '2025-10-13'
 */
export function utcExpiredDate(isoDateString) {
  return setUTCTime(isoDateString);
}

/**
 * Whether the timestamp is within 2 weeks from the current date.
 * @param {string} timestamp
 */
export const isWithin2Weeks = (timestamp) =>
  setUTCTime(timestamp) <= setUTCTime(nDaysAfter(new Date(), 14));

/**
 * Builds an empty permissions object keyed by access scope,
 * with each scope initialized to an empty array.
 * @param {string[]} [keys] - Scope keys to include; defaults to every access scope
 * @returns {Object} e.g. { namespace: [], user: [], instance: [] }
 */
export const emptyByScope = (keys = ACCESS_SCOPE_KEYS) =>
  Object.fromEntries(keys.map((key) => [key, []]));

/**
 * Groups a flat list of permissions by category and resource, with actions nested under each resource.
 *
 * @param {Array} permissions
 * @returns {Array}
 *
 * @example
 * const permissions = [
 *   { name: 'read_runner', action: 'read', resource: 'runner', resourceName: 'Runner', resourceDescription: 'Grants the ability to read runners', category: 'ci_cd', categoryName: 'CI/CD' },
 * ];
 * // Returns:
 * // [
 * //   {
 * //     key: 'ci_cd',
 * //     name: 'CI/CD',
 * //     resources: [
 * //       {
 * //         key: 'runner',
 * //         name: 'Runner',
 * //         description: 'Grants the ability to read runners',
 * //         actions: [
 * //           { value: 'read_runner', text: 'read' }
 * //         ]
 * //       }
 * //     ]
 * //   }
 * // ]
 */
export function groupPermissionsByResourceAndCategory(permissions) {
  const groupedByCategory = groupBy(permissions, 'category');

  return map(groupedByCategory, (items, category) => ({
    key: category,
    name: items[0]?.categoryName,
    resources: map(groupBy(items, 'resource'), (resourceItems, resource) => ({
      key: resource,
      name: resourceItems[0]?.resourceName,
      description: resourceItems[0]?.resourceDescription,
      actions: resourceItems.map((permission) => ({
        key: permission.name,
        name: humanize(permission.action),
      })),
    })),
  }));
}
