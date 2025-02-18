import { queryToObject } from '~/lib/utils/url_utility';
import {
  OPERATORS_BEFORE,
  OPERATORS_AFTER,
} from '~/vue_shared/components/filtered_search_bar/constants';
import { TOKENS } from './constants';

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
  const tokens = [];

  const { search, ...terms } = queryToObject(query);

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

  return tokens;
}
