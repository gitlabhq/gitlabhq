import {
  API_PARAM,
  BLOCKING_ISSUES_DESC,
  CREATED_ASC,
  CREATED_DESC,
  DUE_DATE_ASC,
  DUE_DATE_DESC,
  DUE_DATE_VALUES,
  filters,
  LABEL_PRIORITY_ASC,
  LABEL_PRIORITY_DESC,
  MILESTONE_DUE_ASC,
  MILESTONE_DUE_DESC,
  NORMAL_FILTER,
  POPULARITY_ASC,
  POPULARITY_DESC,
  PRIORITY_ASC,
  PRIORITY_DESC,
  RELATIVE_POSITION_ASC,
  SPECIAL_FILTER,
  SPECIAL_FILTER_VALUES,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_ITERATION,
  UPDATED_ASC,
  UPDATED_DESC,
  URL_PARAM,
  urlSortParams,
  WEIGHT_ASC,
  WEIGHT_DESC,
} from '~/issues_list/constants';
import { isPositiveInteger } from '~/lib/utils/number_utils';
import { __ } from '~/locale';
import {
  FILTERED_SEARCH_TERM,
  OPERATOR_IS_NOT,
} from '~/vue_shared/components/filtered_search_bar/constants';

export const getSortKey = (sort) =>
  Object.keys(urlSortParams).find((key) => urlSortParams[key] === sort);

export const getDueDateValue = (value) => (DUE_DATE_VALUES.includes(value) ? value : undefined);

export const getSortOptions = (hasIssueWeightsFeature, hasBlockedIssuesFeature) => {
  const sortOptions = [
    {
      id: 1,
      title: __('Priority'),
      sortDirection: {
        ascending: PRIORITY_ASC,
        descending: PRIORITY_DESC,
      },
    },
    {
      id: 2,
      title: __('Created date'),
      sortDirection: {
        ascending: CREATED_ASC,
        descending: CREATED_DESC,
      },
    },
    {
      id: 3,
      title: __('Last updated'),
      sortDirection: {
        ascending: UPDATED_ASC,
        descending: UPDATED_DESC,
      },
    },
    {
      id: 4,
      title: __('Milestone due date'),
      sortDirection: {
        ascending: MILESTONE_DUE_ASC,
        descending: MILESTONE_DUE_DESC,
      },
    },
    {
      id: 5,
      title: __('Due date'),
      sortDirection: {
        ascending: DUE_DATE_ASC,
        descending: DUE_DATE_DESC,
      },
    },
    {
      id: 6,
      title: __('Popularity'),
      sortDirection: {
        ascending: POPULARITY_ASC,
        descending: POPULARITY_DESC,
      },
    },
    {
      id: 7,
      title: __('Label priority'),
      sortDirection: {
        ascending: LABEL_PRIORITY_ASC,
        descending: LABEL_PRIORITY_DESC,
      },
    },
    {
      id: 8,
      title: __('Manual'),
      sortDirection: {
        ascending: RELATIVE_POSITION_ASC,
        descending: RELATIVE_POSITION_ASC,
      },
    },
  ];

  if (hasIssueWeightsFeature) {
    sortOptions.push({
      id: 9,
      title: __('Weight'),
      sortDirection: {
        ascending: WEIGHT_ASC,
        descending: WEIGHT_DESC,
      },
    });
  }

  if (hasBlockedIssuesFeature) {
    sortOptions.push({
      id: 10,
      title: __('Blocking'),
      sortDirection: {
        ascending: BLOCKING_ISSUES_DESC,
        descending: BLOCKING_ISSUES_DESC,
      },
    });
  }

  return sortOptions;
};

const tokenTypes = Object.keys(filters);

const getUrlParams = (tokenType) =>
  Object.values(filters[tokenType][URL_PARAM]).flatMap((filterObj) => Object.values(filterObj));

const urlParamKeys = tokenTypes.flatMap(getUrlParams);

const getTokenTypeFromUrlParamKey = (urlParamKey) =>
  tokenTypes.find((tokenType) => getUrlParams(tokenType).includes(urlParamKey));

const getOperatorFromUrlParamKey = (tokenType, urlParamKey) =>
  Object.entries(filters[tokenType][URL_PARAM]).find(([, filterObj]) =>
    Object.values(filterObj).includes(urlParamKey),
  )[0];

const convertToFilteredTokens = (locationSearch) =>
  Array.from(new URLSearchParams(locationSearch).entries())
    .filter(([key]) => urlParamKeys.includes(key))
    .map(([key, data]) => {
      const type = getTokenTypeFromUrlParamKey(key);
      const operator = getOperatorFromUrlParamKey(type, key);
      return {
        type,
        value: { data, operator },
      };
    });

const convertToFilteredSearchTerms = (locationSearch) =>
  new URLSearchParams(locationSearch)
    .get('search')
    ?.split(' ')
    .map((word) => ({
      type: FILTERED_SEARCH_TERM,
      value: {
        data: word,
      },
    })) || [];

export const getFilterTokens = (locationSearch) => {
  if (!locationSearch) {
    return [];
  }
  const filterTokens = convertToFilteredTokens(locationSearch);
  const searchTokens = convertToFilteredSearchTerms(locationSearch);
  return filterTokens.concat(searchTokens);
};

const getFilterType = (data, tokenType = '') =>
  SPECIAL_FILTER_VALUES.includes(data) ||
  (tokenType === TOKEN_TYPE_ASSIGNEE && isPositiveInteger(data))
    ? SPECIAL_FILTER
    : NORMAL_FILTER;

const isIterationSpecialValue = (tokenType, value) =>
  tokenType === TOKEN_TYPE_ITERATION && SPECIAL_FILTER_VALUES.includes(value);

export const convertToApiParams = (filterTokens) => {
  const params = {};
  const not = {};

  filterTokens
    .filter((token) => token.type !== FILTERED_SEARCH_TERM)
    .forEach((token) => {
      const filterType = getFilterType(token.value.data, token.type);
      const field = filters[token.type][API_PARAM][filterType];
      const obj = token.value.operator === OPERATOR_IS_NOT ? not : params;
      const data = isIterationSpecialValue(token.type, token.value.data)
        ? token.value.data.toUpperCase()
        : token.value.data;
      Object.assign(obj, {
        [field]: obj[field] ? [obj[field], data].flat() : data,
      });
    });

  return Object.keys(not).length ? Object.assign(params, { not }) : params;
};

export const convertToUrlParams = (filterTokens) =>
  filterTokens
    .filter((token) => token.type !== FILTERED_SEARCH_TERM)
    .reduce((acc, token) => {
      const filterType = getFilterType(token.value.data, token.type);
      const param = filters[token.type][URL_PARAM][token.value.operator]?.[filterType];
      return Object.assign(acc, {
        [param]: acc[param] ? [acc[param], token.value.data].flat() : token.value.data,
      });
    }, {});

export const convertToSearchQuery = (filterTokens) =>
  filterTokens
    .filter((token) => token.type === FILTERED_SEARCH_TERM && token.value.data)
    .map((token) => token.value.data)
    .join(' ');
