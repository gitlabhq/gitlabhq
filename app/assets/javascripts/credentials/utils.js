import { queryToObject, setUrlParams } from '~/lib/utils/url_utility';
import {
  OPERATORS_BEFORE,
  OPERATORS_AFTER,
} from '~/vue_shared/components/filtered_search_bar/constants';
import { TOKENS, SORT_OPTIONS, DEFAULT_SORT } from './constants';

/**
 * @typedef {{type: string, value: {data: string, operator: string}}} Token
 */

/**
 * Initialize token values based on the URL parameters
 * @param {string} query - document.location.search
 *
 * @returns {Array<string|Token>}
 */
export function initializeValuesFromQuery(query = document.location.search) {
  const tokens = /** @type {Array<string|Token>} */ ([]);
  const sorting = DEFAULT_SORT;

  const { search, sort, ...terms } = queryToObject(query);

  for (const [key, value] of Object.entries(terms)) {
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
        const { operators } = TOKENS.find(({ options }) =>
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

  const sortOption = SORT_OPTIONS.find((item) => [item.sort.desc, item.sort.asc].includes(sort));
  if (sort && sortOption) {
    sorting.value = sortOption.value;
    sorting.isAsc = sortOption.sort.asc === sort;
  }

  return { tokens, sorting };
}

export function buildSortedUrl(value, isAsc) {
  const sortedOption = SORT_OPTIONS.find((sortOption) => sortOption.value === value);
  const sort = isAsc ? sortedOption.sort.asc : sortedOption.sort.desc;
  const newUrl = setUrlParams({ sort });
  return newUrl;
}
