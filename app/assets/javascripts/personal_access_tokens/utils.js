import { localeDateFormat, newDate } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';
import {
  OPERATORS_AFTER,
  OPERATORS_BEFORE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import { FILTERED_SEARCH_TERM_KEY } from './constants';

const emptyDateField = __('Never');

export const timeFormattedAsDate = (time) =>
  time ? localeDateFormat.asDate.format(newDate(time)) : emptyDateField;

export const timeFormattedAsDateFull = (time) =>
  time ? localeDateFormat.asDateTimeFull.format(newDate(time)) : emptyDateField;

/* eslint-disable @gitlab/require-i18n-strings */
function getSuffixFromOperator(operator) {
  if (operator === OPERATORS_BEFORE[0].value) return 'Before';
  if (operator === OPERATORS_AFTER[0].value) return 'After';

  return '';
}
/* eslint-enable @gitlab/require-i18n-strings */

/**
 * Converts an array of filter tokens into a flat object of query variables.
 *
 * Transforms filter tokens into key-value pairs suitable for API queries or URL parameters.
 * Applies operator-based suffixes to filter keys
 * (e.g., 'After' for >, 'Before' for <) to support date fields such as `expires`.
 *
 * @param {Array<Object>} filters - Filter token objects
 * @param {string} filters[].type - Filter type (e.g., 'expires', 'state', 'filtered-search-term')
 * @param {Object} filters[].value - Filter value with data and optional operator
 * @param {*} filters[].value.data - The filter value
 * @param {string} [filters[].value.operator] - Filter operator ('<', '≥', '=')
 *
 * @returns {Object} Object with filter keys mapped to their data value
 *
 * @example
 * // Input: [{ type: 'expires', value: { data: '2026-01-20', operator: '<' } }]
 * // Output: { expiresBefore: '2026-01-20' }
 *
 * @example
 * // Input: [{ type: 'filtered-search-term', value: { data: 'token name' } }]
 * // Output: { search: 'token name' }
 */
export function convertFiltersToVariables(filters) {
  return Object.fromEntries(
    filters.flatMap((filterToken) => {
      const { type, value } = filterToken;

      if (!value?.data) return [];

      if (type === 'filtered-search-term') {
        return [[FILTERED_SEARCH_TERM_KEY, value.data]];
      }

      const suffix = getSuffixFromOperator(value.operator);

      return [[`${type}${suffix}`, value.data]];
    }),
  );
}
