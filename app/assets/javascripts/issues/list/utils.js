import produce from 'immer';
import { isPositiveInteger } from '~/lib/utils/number_utils';
import { getParameterByName } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import {
  FILTERED_SEARCH_TERM,
  OPERATOR_NOT,
  OPERATOR_OR,
  OPERATOR_AFTER,
  OPERATORS_TO_GROUP,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_ITERATION,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_TYPE,
  TOKEN_TYPE_HEALTH,
  TOKEN_TYPE_LABEL,
} from '~/vue_shared/components/filtered_search_bar/constants';
import { DEFAULT_PAGE_SIZE } from '~/vue_shared/issuable/list/constants';
import {
  WORK_ITEM_TO_ISSUE_MAP,
  WIDGET_TYPE_MILESTONE,
  WIDGET_TYPE_AWARD_EMOJI,
  EMOJI_THUMBSUP,
  EMOJI_THUMBSDOWN,
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_LABELS,
} from '~/work_items/constants';
import { STATUS_CLOSED, STATUS_OPEN } from '../constants';
import {
  ALTERNATIVE_FILTER,
  API_PARAM,
  BLOCKING_ISSUES_ASC,
  BLOCKING_ISSUES_DESC,
  CLOSED_AT_ASC,
  CLOSED_AT_DESC,
  CREATED_ASC,
  CREATED_DESC,
  DUE_DATE_ASC,
  DUE_DATE_DESC,
  filtersMap,
  HEALTH_STATUS_ASC,
  HEALTH_STATUS_DESC,
  LABEL_PRIORITY_ASC,
  LABEL_PRIORITY_DESC,
  MILESTONE_DUE_ASC,
  MILESTONE_DUE_DESC,
  NORMAL_FILTER,
  PARAM_ASSIGNEE_ID,
  POPULARITY_ASC,
  POPULARITY_DESC,
  PRIORITY_ASC,
  PRIORITY_DESC,
  RELATIVE_POSITION_ASC,
  SPECIAL_FILTER,
  specialFilterValues,
  TITLE_ASC,
  TITLE_DESC,
  UPDATED_ASC,
  UPDATED_DESC,
  URL_PARAM,
  urlSortParams,
  WEIGHT_ASC,
  WEIGHT_DESC,
} from './constants';

export const getInitialPageParams = (
  pageSize,
  firstPageSize = pageSize ?? DEFAULT_PAGE_SIZE,
  lastPageSize,
  afterCursor,
  beforeCursor,
) => ({
  firstPageSize: lastPageSize ? undefined : firstPageSize,
  lastPageSize,
  afterCursor,
  beforeCursor,
});

export const getSortKey = (sort, sortMap = urlSortParams) =>
  Object.keys(sortMap).find((key) => sortMap[key] === sort);

export const isSortKey = (sort, sortMap = urlSortParams) => Object.keys(sortMap).includes(sort);

export const deriveSortKey = ({ sort, sortMap, state = STATUS_OPEN }) => {
  const defaultSortKey = state === STATUS_CLOSED ? UPDATED_DESC : CREATED_DESC;
  const legacySortKey = getSortKey(sort, sortMap);
  const graphQLSortKey = isSortKey(sort?.toUpperCase(), sortMap) && sort.toUpperCase();

  return legacySortKey || graphQLSortKey || defaultSortKey;
};

export const getSortOptions = ({
  hasBlockedIssuesFeature,
  hasIssuableHealthStatusFeature,
  hasIssueWeightsFeature,
  hasManualSort = true,
} = {}) => {
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
      title: __('Updated date'),
      sortDirection: {
        ascending: UPDATED_ASC,
        descending: UPDATED_DESC,
      },
    },
    {
      id: 4,
      title: __('Closed date'),
      sortDirection: {
        ascending: CLOSED_AT_ASC,
        descending: CLOSED_AT_DESC,
      },
    },
    {
      id: 5,
      title: __('Milestone due date'),
      sortDirection: {
        ascending: MILESTONE_DUE_ASC,
        descending: MILESTONE_DUE_DESC,
      },
    },
    {
      id: 6,
      title: __('Due date'),
      sortDirection: {
        ascending: DUE_DATE_ASC,
        descending: DUE_DATE_DESC,
      },
    },
    {
      id: 7,
      title: __('Popularity'),
      sortDirection: {
        ascending: POPULARITY_ASC,
        descending: POPULARITY_DESC,
      },
    },
    {
      id: 8,
      title: __('Label priority'),
      sortDirection: {
        ascending: LABEL_PRIORITY_ASC,
        descending: LABEL_PRIORITY_DESC,
      },
    },
    hasManualSort && {
      id: 9,
      title: __('Manual'),
      sortDirection: {
        ascending: RELATIVE_POSITION_ASC,
        descending: RELATIVE_POSITION_ASC,
      },
    },
    {
      id: 10,
      title: __('Title'),
      sortDirection: {
        ascending: TITLE_ASC,
        descending: TITLE_DESC,
      },
    },
  ];

  if (hasIssuableHealthStatusFeature) {
    sortOptions.push({
      id: sortOptions.length + 1,
      title: __('Health'),
      sortDirection: {
        ascending: HEALTH_STATUS_ASC,
        descending: HEALTH_STATUS_DESC,
      },
    });
  }

  if (hasIssueWeightsFeature) {
    sortOptions.push({
      id: sortOptions.length + 1,
      title: __('Weight'),
      sortDirection: {
        ascending: WEIGHT_ASC,
        descending: WEIGHT_DESC,
      },
    });
  }

  if (hasBlockedIssuesFeature) {
    sortOptions.push({
      id: sortOptions.length + 1,
      title: __('Blocking'),
      sortDirection: {
        ascending: BLOCKING_ISSUES_ASC,
        descending: BLOCKING_ISSUES_DESC,
      },
    });
  }

  return sortOptions.filter((x) => x);
};

const tokenTypes = Object.keys(filtersMap);

const getUrlParams = (tokenType) =>
  Object.values(filtersMap[tokenType][URL_PARAM]).flatMap((filterObj) => Object.values(filterObj));

const urlParamKeys = tokenTypes.flatMap(getUrlParams);

const getTokenTypeFromUrlParamKey = (urlParamKey) =>
  tokenTypes.find((tokenType) => getUrlParams(tokenType).includes(urlParamKey));

const getOperatorFromUrlParamKey = (tokenType, urlParamKey) =>
  Object.entries(filtersMap[tokenType][URL_PARAM]).find(([, filterObj]) =>
    Object.values(filterObj).includes(urlParamKey),
  )[0];

export const getFilterTokens = (locationSearch) =>
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

export function groupMultiSelectFilterTokens(filterTokensToGroup, tokenDefs) {
  const groupedTokens = [];

  const multiSelectTokenTypes = tokenDefs.filter((t) => t.multiSelect).map((t) => t.type);

  filterTokensToGroup.forEach((token) => {
    const shouldGroup =
      OPERATORS_TO_GROUP.includes(token.value.operator) &&
      multiSelectTokenTypes.includes(token.type);

    if (!shouldGroup) {
      groupedTokens.push(token);
      return;
    }

    const sameTypeAndOperator = (t) =>
      t.type === token.type && t.value.operator === token.value.operator;
    const existingToken = groupedTokens.find(sameTypeAndOperator);

    if (!existingToken) {
      groupedTokens.push({
        ...token,
        value: {
          ...token.value,
          data: [token.value.data],
        },
      });
    } else if (!existingToken.value.data.includes(token.value.data)) {
      existingToken.value.data.push(token.value.data);
    }
  });

  return groupedTokens;
}

export const isNotEmptySearchToken = (token) =>
  !(token.type === FILTERED_SEARCH_TERM && !token.value.data);

export const isSpecialFilter = (type, data) => {
  const isAssigneeIdParam =
    type === TOKEN_TYPE_ASSIGNEE &&
    isPositiveInteger(data) &&
    getParameterByName(PARAM_ASSIGNEE_ID) === data;
  return specialFilterValues.includes(data) || isAssigneeIdParam;
};

const getFilterType = ({ type, value: { data, operator } }) => {
  const isUnionedAuthor = type === TOKEN_TYPE_AUTHOR && operator === OPERATOR_OR;
  const isUnionedLabel = type === TOKEN_TYPE_LABEL && operator === OPERATOR_OR;
  const isAfter = operator === OPERATOR_AFTER;

  if (isUnionedAuthor || isUnionedLabel || isAfter) {
    return ALTERNATIVE_FILTER;
  }
  if (isSpecialFilter(type, data)) {
    return SPECIAL_FILTER;
  }
  return NORMAL_FILTER;
};

const wildcardTokens = [TOKEN_TYPE_ITERATION, TOKEN_TYPE_MILESTONE, TOKEN_TYPE_RELEASE];

const isWildcardValue = (tokenType, value) =>
  wildcardTokens.includes(tokenType) && specialFilterValues.includes(value);

const isHealthStatusSpecialFilter = (tokenType, value) =>
  tokenType === TOKEN_TYPE_HEALTH && specialFilterValues.includes(value);

const requiresUpperCaseValue = (tokenType, value) =>
  tokenType === TOKEN_TYPE_TYPE ||
  isWildcardValue(tokenType, value) ||
  isHealthStatusSpecialFilter(tokenType, value);

const formatData = (token) => {
  if (requiresUpperCaseValue(token.type, token.value.data)) {
    return token.value.data.toUpperCase();
  }
  if (token.type === TOKEN_TYPE_CONFIDENTIAL) {
    return token.value.data === 'yes';
  }
  return token.value.data;
};

export const convertToApiParams = (filterTokens) => {
  const params = new Map();
  const not = new Map();
  const or = new Map();

  filterTokens.filter(isNotEmptySearchToken).forEach((token) => {
    const filterType = getFilterType(token);
    const apiField = filtersMap[token.type][API_PARAM][filterType];
    let obj;
    if (token.value.operator === OPERATOR_NOT) {
      obj = not;
    } else if (token.value.operator === OPERATOR_OR) {
      obj = or;
    } else {
      obj = params;
    }
    const data = formatData(token);
    obj.set(apiField, obj.has(apiField) ? [obj.get(apiField), data].flat() : data);
  });

  if (not.size) {
    params.set('not', Object.fromEntries(not));
  }

  if (or.size) {
    params.set('or', Object.fromEntries(or));
  }

  return Object.fromEntries(params);
};

export const convertToUrlParams = (filterTokens) => {
  const urlParamsMap = filterTokens.filter(isNotEmptySearchToken).reduce((acc, token) => {
    const filterType = getFilterType(token);
    const urlParam = filtersMap[token.type][URL_PARAM][token.value.operator]?.[filterType];
    return acc.set(
      urlParam,
      acc.has(urlParam) ? [acc.get(urlParam), token.value.data].flat() : token.value.data,
    );
  }, new Map());

  return Object.fromEntries(urlParamsMap);
};

export const convertToSearchQuery = (filterTokens) =>
  filterTokens
    .filter((token) => token.type === FILTERED_SEARCH_TERM && token.value.data)
    .map((token) => token.value.data)
    .join(' ') || undefined;

function findWidget(type, workItem) {
  return workItem?.widgets?.find((widget) => widget.type === type);
}

export function mapWorkItemWidgetsToIssueFields(issuesList, workItem) {
  return produce(issuesList, (draftData) => {
    const activeItem = draftData.project.issues.nodes.find((issue) => issue.iid === workItem.iid);

    Object.keys(WORK_ITEM_TO_ISSUE_MAP).forEach((type) => {
      const currentWidget = findWidget(type, workItem);
      if (!currentWidget) {
        return;
      }
      const property = WORK_ITEM_TO_ISSUE_MAP[type];

      // handling the case for assignees and labels
      if (
        property === WORK_ITEM_TO_ISSUE_MAP[WIDGET_TYPE_ASSIGNEES] ||
        property === WORK_ITEM_TO_ISSUE_MAP[WIDGET_TYPE_LABELS]
      ) {
        activeItem[property] = {
          ...currentWidget[property],
          nodes: currentWidget[property].nodes.map((node) => ({
            __persist: true,
            ...node,
          })),
        };
        return;
      }

      // handling the case for milestone
      if (property === WORK_ITEM_TO_ISSUE_MAP[WIDGET_TYPE_MILESTONE] && currentWidget[property]) {
        activeItem[property] = { __persist: true, ...currentWidget[property] };
        return;
      }
      activeItem[property] = currentWidget[property];
    });

    activeItem.title = workItem.title;
    activeItem.confidential = workItem.confidential;
  });
}

export function updateUpvotesCount(issuesList, workItem) {
  const type = WIDGET_TYPE_AWARD_EMOJI;
  const property = WORK_ITEM_TO_ISSUE_MAP[type];

  return produce(issuesList, (draftData) => {
    const activeItem = draftData.project.issues.nodes.find((issue) => issue.iid === workItem.iid);

    const currentWidget = findWidget(type, workItem);
    if (!currentWidget) {
      return;
    }

    const upvotesCount =
      currentWidget[property].nodes.filter((emoji) => emoji.name === EMOJI_THUMBSUP)?.length ?? 0;
    const downvotesCount =
      currentWidget[property].nodes.filter((emoji) => emoji.name === EMOJI_THUMBSDOWN)?.length ?? 0;
    activeItem.upvotes = upvotesCount;
    activeItem.downvotes = downvotesCount;
  });
}
