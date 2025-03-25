import { queryToObject, setUrlParams, visitUrl } from '~/lib/utils/url_utility';
import {
  OPERATORS_BEFORE,
  OPERATORS_AFTER,
} from '~/vue_shared/components/filtered_search_bar/constants';
import { DEFAULT_SORT, SORT_OPTIONS, TOKENS } from '~/access_tokens/constants';

/**
 * @param {Object<string, string>} filters
 * @param {string} [search]
 */
function initializeFilters(filters, search) {
  const tokens = [];

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

  return tokens;
}

/**
 * @param {string} [sort]
 */
function initializeSort(sort) {
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
 * Initialize tokens and sort based on the URL parameters
 * @param {string} query - document.location.search
 */
export function initializeValuesFromQuery(query = document.location.search) {
  const { sort, search, ...filters } = queryToObject(query);
  const sorting = initializeSort(sort);
  const tokens = initializeFilters(filters, search);

  return { sorting, tokens };
}

/**
 * @param {string} sortValue
 * @param {boolean} sortIsAsc
 * @param {Array<string|{type: string, value:{data: string, operator: string}}>} tokens
 */
export function goTo(sortValue, sortIsAsc, tokens) {
  const newParams = { page: 1 };

  tokens?.forEach((token) => {
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

  const sortOption = SORT_OPTIONS.find((item) => item.value === sortValue).sort;
  newParams.sort = sortIsAsc ? sortOption.asc : sortOption.desc;
  const newUrl = setUrlParams(newParams, window.location.href, true);
  visitUrl(newUrl);
}
