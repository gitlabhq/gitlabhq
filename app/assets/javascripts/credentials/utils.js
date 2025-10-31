import { setUrlParams, visitUrl } from '~/lib/utils/url_utility';
import { SORT_OPTIONS } from '~/access_tokens/constants';

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
  const newUrl = setUrlParams(newParams, { url: window.location.href, clearParams: true });
  visitUrl(newUrl);
}
