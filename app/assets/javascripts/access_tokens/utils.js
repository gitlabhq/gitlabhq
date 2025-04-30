import { queryToObject } from '~/lib/utils/url_utility';
import {
  OPERATORS_BEFORE,
  OPERATORS_AFTER,
} from '~/vue_shared/components/filtered_search_bar/constants';
import {
  DEFAULT_FILTER,
  DEFAULT_SORT,
  FILTER_OPTIONS,
  FILTER_OPTIONS_CREDENTIALS_INVENTORY,
  SORT_OPTIONS,
} from './constants';

/**
 * Parses filters as provided in the URL and returns a set of tokens.
 * For example, a URL like `{ created_before: '2022-12-31' }` will return an array of
 * tokens like `[{ type: 'created', value: { data: '2022-12-31', operator: '<' }}]`.
 * @param {Object<string, string>} filters
 * @param {string} [search]
 * @param {boolean} isCredentialsInventory
 */
export function initializeFilters(filters, search, isCredentialsInventory) {
  const tokens = [];
  const filterOptions = isCredentialsInventory
    ? FILTER_OPTIONS_CREDENTIALS_INVENTORY
    : FILTER_OPTIONS;

  for (const [key, value] of Object.entries(filters)) {
    const isBefore = key.endsWith('_before');
    const isAfter = key.endsWith('_after');

    if (isBefore || isAfter) {
      tokens.push({
        type: key.replace(/_(before|after)$/, ''),
        value: {
          data: value,
          operator: isBefore ? OPERATORS_BEFORE[0].value : OPERATORS_AFTER[0].value,
        },
      });
    } else {
      try {
        const { operators } = filterOptions.find(({ options }) =>
          options.some((option) => option.value === value),
        );
        tokens.push({
          type: key,
          value: {
            data: value,
            operator: operators[0].value,
          },
        });
      } catch {
        // Unknown token
      }
    }
  }

  if (search) {
    tokens.push(search);
  }

  if (!isCredentialsInventory && tokens.length === 0) {
    return DEFAULT_FILTER;
  }

  return tokens;
}

/**
 * Parses sort the option as provided in the URL and returns a proper structure.
 * For example, a URL like `created_asc` will return `{ value: 'created', isAsc: true}`.
 * @param {string} [sort]
 */
export function initializeSort(sort) {
  let sorting = DEFAULT_SORT;

  const sortOption = SORT_OPTIONS.find((item) => [item.sort.desc, item.sort.asc].includes(sort));
  if (sortOption) {
    sorting = {
      value: sortOption.value,
      isAsc: sortOption.sort.asc === sort,
    };
  }

  return sorting;
}

/**
 * Parses the query params from the URL and returns an object with filters/tokens, page, and sorting.
 * @param {boolean} [isCredentialsInventory]
 * @param {string} [query] - document.location.search
 */
export function initializeValuesFromQuery(
  isCredentialsInventory = false,
  query = document.location.search,
) {
  const { page, search, sort, ...filters } = queryToObject(query);
  const tokens = initializeFilters(filters, search, isCredentialsInventory);
  const sorting = initializeSort(sort);

  return {
    ...(isCredentialsInventory ? { tokens } : { filters: tokens }),
    page: parseInt(page, 10) || 1,
    sorting,
  };
}
