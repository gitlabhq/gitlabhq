import { map, groupBy } from 'lodash-es';
import { queryToObject } from '~/lib/utils/url_utility';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { localeDateFormat, newDate } from '~/lib/utils/datetime_utility';
import { convertToSnakeCase, humanize } from '~/lib/utils/text_utility';
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

/**
 * Builds the URL to redirect to the granular token creation form pre-populated
 * from an existing token. The form fetches the source token's full scope data
 * server-side using the ID, so no scope data is encoded in the URL.
 * @param {Object} token - The token to duplicate (must have an `id` field)
 * @param {string} granularNewUrl - The base URL for the granular token creation form
 * @returns {string} URL with source_token_id query parameter
 */
export function buildDuplicateUrl(token, granularNewUrl) {
  const params = new URLSearchParams({ source_token_id: getIdFromGraphQLId(token.id) });
  const separator = granularNewUrl.includes('?') ? '&' : '?';
  return `${granularNewUrl}${separator}${params}`;
}
