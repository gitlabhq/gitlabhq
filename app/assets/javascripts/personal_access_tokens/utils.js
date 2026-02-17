import { map, groupBy, uniqBy } from 'lodash';
import { queryToObject } from '~/lib/utils/url_utility';
import { localeDateFormat, newDate } from '~/lib/utils/datetime_utility';
import { convertToSnakeCase } from '~/lib/utils/text_utility';
import { __ } from '~/locale';
import {
  OPERATORS_AFTER,
  OPERATORS_BEFORE,
  OPERATORS_IS,
  FILTERED_SEARCH_TERM,
} from '~/vue_shared/components/filtered_search_bar/constants';
import { SEARCH, FILTER_OPTIONS, SORT_OPTIONS, DEFAULT_FILTER, DEFAULT_SORT } from './constants';

const emptyDateField = __('Never');

/**
 * Formats a timestamp as a localized date string
 * @param {string|Date} time - The timestamp or Date object to format
 * @returns {string} Formatted date string in local format (e.g., "Jan 15, 2024")
 * @example
 * timeFormattedAsDate('2024-01-15T10:30:00Z') // Returns: "Jan 15, 2024"
 * timeFormattedAsDate(null) // Returns: "Never"
 */
export const timeFormattedAsDate = (time) =>
  time ? localeDateFormat.asDate.format(newDate(time)) : emptyDateField;

/**
 * Formats a timestamp as a full localized date and time string
 * @param {string|Date} time - The timestamp or Date object to format
 * @returns {string} Formatted date and time string (e.g., "Jan 15, 2024 at 10:30 AM")
 * @example
 * timeFormattedAsDateFull('2024-01-15T10:30:00Z') // Returns: "Jan 15, 2024 at 10:30 AM"
 * timeFormattedAsDateFull(null) // Returns: "Never"
 */
export const timeFormattedAsDateFull = (time) =>
  time ? localeDateFormat.asDateTimeFull.format(newDate(time)) : emptyDateField;

/* eslint-disable @gitlab/require-i18n-strings */
/**
 * Gets the GraphQL operator suffix based on filter operator
 * @param {string} operator - The filter operator (=, >, <)
 * @returns {string} The suffix to append to the filter field name
 * @private
 * @example
 * getSuffixFromOperator('>') // Returns: 'After'
 * getSuffixFromOperator('<') // Returns: 'Before'
 * getSuffixFromOperator('=') // Returns: ''
 */
function getSuffixFromOperator(operator) {
  if (operator === OPERATORS_BEFORE[0].value) return 'Before';
  if (operator === OPERATORS_AFTER[0].value) return 'After';

  return '';
}
/* eslint-enable @gitlab/require-i18n-strings */

/**
 * Gets the filter operator from a query parameter key
 * @param {string} suffix - The query parameter key
 * @returns {string} The corresponding filter operator
 * @private
 * @example
 * getOperatorFromSuffix('_after') // Returns: '>'
 * getOperatorFromSuffix('expires_before') // Returns: '<'
 * getOperatorFromSuffix('state') // Returns: '='
 */
function getOperatorFromSuffix(suffix) {
  if (suffix.endsWith('_after')) return OPERATORS_AFTER[0].value;
  if (suffix.endsWith('_before')) return OPERATORS_BEFORE[0].value;

  return OPERATORS_IS[0].value;
}

/**
 * Parses and converts query parameter values to appropriate types
 * Handles boolean string conversion and case normalization
 * @param {string} value - The raw query parameter value
 * @returns {string|boolean} The parsed value with correct type
 * @private
 * @example
 * parseFilterValue('true') // Returns: true
 * parseFilterValue('false') // Returns: false
 * parseFilterValue('active') // Returns: 'ACTIVE'
 */
function parseFilterValue(value) {
  if (value === 'true') return true;
  if (value === 'false') return false;

  return value.toUpperCase();
}

/**
 * Converts an array of filter tokens to GraphQL query variables
 * @param {Array} filters - Array of filter token objects with type and value properties
 * @returns {Object} Object with filter variables for GraphQL queries
 * @example
 * const filters = [
 *   { type: 'state', value: { operator: '=', data: 'ACTIVE' } },
 *   { type: 'filtered-search-term', value: { data: 'my-token' } }
 * ];
 * // Returns: { state: 'ACTIVE', search: 'my-token' }
 */
export function convertFiltersToVariables(filters) {
  return Object.fromEntries(
    filters.flatMap((filterToken) => {
      const {
        type,
        value: { operator, data },
      } = filterToken;

      if (data == null || data === '') return [];

      if (type === FILTERED_SEARCH_TERM) {
        return [[SEARCH, data]];
      }

      const suffix = getSuffixFromOperator(operator);

      return [[`${type}${suffix}`, data]];
    }),
  );
}

/**
 * Initializes filter tokens from URL query parameters
 * Parses the current URL search params and converts them back to filter token format
 * @returns {Array} Array of filter token objects or default filter if no params found
 * @example
 * // URL: ?state=active&created_after=2024-01-01&search=token
 * // Returns: [
 * //   { type: 'state', value: { operator: '=', data: 'ACTIVE' } },
 * //   { type: 'created', value: { operator: '>', data: '2024-01-01' } },
 * //   { type: 'filtered-search-term', value: { data: 'token' } }
 * // ]
 */
export function initializeFilterFromQueryParams() {
  const { search, sort, ...filters } = queryToObject(window.location.search);

  const filterTokens = [];

  Object.entries(filters).forEach(([key, value]) => {
    const operator = getOperatorFromSuffix(key);
    const filterType = key.replace(/_(after|before)$/, '');

    // skip if filter type not found in FILTER_OPTIONS
    const filterConfig = FILTER_OPTIONS.find((filter) => filter.type === filterType);
    if (!filterConfig) {
      return;
    }

    filterTokens.push({
      type: filterType,
      value: {
        data: parseFilterValue(value),
        operator,
      },
    });
  });

  if (search) {
    filterTokens.push({
      type: FILTERED_SEARCH_TERM,
      value: {
        data: search,
      },
    });
  }

  return filterTokens.length > 0 ? filterTokens : structuredClone(DEFAULT_FILTER);
}

/**
 * Initializes sort configuration from URL query parameters
 * Parses the sort parameter and converts it to internal sort object format
 * @returns {Object} Sort object with value and isAsc properties, or default sort if invalid
 * @example
 * // URL: ?sort=created_at_desc
 * // Returns: { sort: { value: 'created_at', isAsc: false } }
 */
export function initializeSortFromQueryParams() {
  const { sort } = queryToObject(window.location.search);

  const sortOption = SORT_OPTIONS.find(
    (option) => option.sort.asc === sort || option.sort.desc === sort,
  );

  if (!sortOption) {
    return structuredClone(DEFAULT_SORT);
  }

  return {
    value: sortOption.value,
    isAsc: sortOption.sort.asc === sort,
  };
}

/**
 * Converts filter object to URL query parameters
 * Transforms camelCase filter keys to snake_case and formats values for URL
 * @param {Object} filterObject - The filter variables object from convertFiltersToVariables
 * @returns {Object} Query parameters object suitable for URL encoding
 * @example
 * const filterObject = { createdAfter: '2024-01-01', state: 'ACTIVE' };
 * // Returns: { created_after: '2024-01-01', state: 'active' }
 */
export function convertFiltersToQueryParams(filterObject) {
  const params = {};

  for (const [key, value] of Object.entries(filterObject)) {
    params[convertToSnakeCase(key)] = value.toString().toLowerCase();
  }

  return params;
}

/**
 * Converts sort object to URL query parameter
 * Formats the internal sort object into a URL-friendly sort parameter
 * @param {Object} sort - The sort object with value and isAsc properties
 * @param {string} sort.value - The field name to sort by
 * @param {boolean} sort.isAsc - Whether to sort in ascending order
 * @returns {Object} Query parameter object with sort key
 * @example
 * const sort = { value: 'created_at', isAsc: false };
 * // Returns: { sort: 'created_at_desc' }
 */
export function convertSortToQueryParams(sort) {
  return {
    sort: `${sort.value}_${sort.isAsc ? 'asc' : 'desc'}`,
  };
}

/**
 * Groups permissions by category and resources
 * Organizes an array of permission objects into a nested structure grouped by category and resource
 * @param {Array} permissions - Array of permission objects, each with a resource and category
 * @param {string} permissions[].resource - The resource name (e.g., 'issues', 'merge_requests')
 * @param {string} permissions[].category - The permission category (e.g., 'read', 'write', 'admin')
 * @returns {Object} Nested object with categories as keys, containing resources and their permissions
 * @example
 * const permissions = [
 *   { name: 'create_issue', action: 'create', resource: 'issue', resourceName: 'Issue', resourceDescription: 'Grants the ability to create issues', category: 'projects', categoryName: 'Projects' },
 * ];
 * // Returns: [
 * //   {
 * //     key: 'projects',
 * //     name: 'Projects',
 * //     resources: [
 * //       { key: 'issue', name: 'Issue', description: 'Grants the ability to create issues' }
 * //     ]
 * //   }
 * // ]
 */
export function groupPermissionsByResourceAndCategory(permissions) {
  const grouped = groupBy(permissions, 'category');

  return map(grouped, (items, category) => ({
    key: category,
    name: items[0]?.categoryName,
    resources: uniqBy(
      items.map((permission) => ({
        key: permission.resource,
        name: permission.resourceName,
        description: permission.resourceDescription,
      })),
      'key',
    ),
  }));
}
