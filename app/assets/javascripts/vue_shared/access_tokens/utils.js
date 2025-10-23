import {
  getDateInFuture,
  nDaysAfter,
  setUTCTime,
  toISODateFormat,
} from '~/lib/utils/datetime_utility';
import { STATISTICS_CONFIG } from '~/access_tokens/constants';

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
  const clonedStats = structuredClone(stats);
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
