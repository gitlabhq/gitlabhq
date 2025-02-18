import produce from 'immer';
import { TYPENAME_ITERATIONS_CADENCE } from '~/graphql_shared/constants';
import { getIdFromGraphQLId, convertToGraphQLId } from '~/graphql_shared/utils';
import { isPositiveInteger } from '~/lib/utils/number_utils';
import { getParameterByName } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import {
  FILTERED_SEARCH_TERM,
  OPERATOR_NOT,
  OPERATOR_OR,
  OPERATOR_AFTER,
  OPERATORS_TO_GROUP,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_REVIEWER,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_DRAFT,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_ITERATION,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_TYPE,
  TOKEN_TYPE_HEALTH,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_EPIC,
  TOKEN_TYPE_WEIGHT,
  TOKEN_TYPE_STATE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import { DEFAULT_PAGE_SIZE } from '~/vue_shared/issuable/list/constants';
import {
  WORK_ITEM_TO_ISSUABLE_MAP,
  WIDGET_TYPE_MILESTONE,
  WIDGET_TYPE_AWARD_EMOJI,
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_LABELS,
  WORK_ITEM_TYPE_ENUM_ISSUE,
  WORK_ITEM_TYPE_ENUM_INCIDENT,
  WORK_ITEM_TYPE_ENUM_TASK,
} from '~/work_items/constants';
import { EMOJI_THUMBS_UP, EMOJI_THUMBS_DOWN } from '~/emoji/constants';
import { BoardType } from '~/boards/constants';
import { STATUS_CLOSED, STATUS_OPEN, TYPE_EPIC } from '../constants';
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
  WILDCARD_FILTER,
  wildcardFilterValues,
  TITLE_ASC,
  TITLE_DESC,
  UPDATED_ASC,
  UPDATED_DESC,
  URL_PARAM,
  urlSortParams,
  WEIGHT_ASC,
  WEIGHT_DESC,
  MERGED_AT_ASC,
  MERGED_AT_DESC,
} from './constants';

/**
 * Get the types of work items that should be displayed on issues lists.
 * This should be consistent with `Issue::TYPES_FOR_LIST` in the backend.
 *
 * @returns {Array<string>}
 */
export const getDefaultWorkItemTypes = () => [
  WORK_ITEM_TYPE_ENUM_ISSUE,
  WORK_ITEM_TYPE_ENUM_INCIDENT,
  WORK_ITEM_TYPE_ENUM_TASK,
];

export const getTypeTokenOptions = () => [
  { icon: 'issue-type-issue', title: s__('WorkItem|Issue'), value: 'issue' },
  { icon: 'issue-type-incident', title: s__('WorkItem|Incident'), value: 'incident' },
  { icon: 'issue-type-task', title: s__('WorkItem|Task'), value: 'task' },
];

export const getInitialPageParams = (
  pageSize,
  firstPageSize = pageSize ?? DEFAULT_PAGE_SIZE,
  lastPageSize,
  afterCursor,
  beforeCursor,
  // eslint-disable-next-line max-params
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
  hasMergedDate = false,
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

  if (hasMergedDate) {
    sortOptions.push({
      id: sortOptions.length + 1,
      title: s__('SortOptions|Merged date'),
      sortDirection: {
        ascending: MERGED_AT_ASC,
        descending: MERGED_AT_DESC,
      },
    });
  }

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

export const getFilterTokens = (locationSearch, includeStateToken = false) =>
  Array.from(new URLSearchParams(locationSearch).entries())
    .filter(
      ([key]) => urlParamKeys.includes(key) && (includeStateToken || key !== TOKEN_TYPE_STATE),
    )
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

export const isAssigneeIdParam = (type, data) => {
  return (
    type === TOKEN_TYPE_ASSIGNEE &&
    isPositiveInteger(data) &&
    getParameterByName(PARAM_ASSIGNEE_ID) === data
  );
};

export const isIterationCadenceIdParam = (type, data) => {
  return type === TOKEN_TYPE_ITERATION && data?.includes('&');
};

const getFilterType = ({ type, value: { data, operator } }) => {
  const isUnionedAuthor = type === TOKEN_TYPE_AUTHOR && operator === OPERATOR_OR;
  const isUnionedLabel = type === TOKEN_TYPE_LABEL && operator === OPERATOR_OR;
  const isAfter = operator === OPERATOR_AFTER;

  if (
    isUnionedAuthor ||
    isUnionedLabel ||
    isAssigneeIdParam(type, data) ||
    isIterationCadenceIdParam(type, data) ||
    isAfter
  ) {
    return ALTERNATIVE_FILTER;
  }
  if (wildcardFilterValues.includes(data)) {
    return WILDCARD_FILTER;
  }

  return NORMAL_FILTER;
};

const wildcardTokens = [
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_EPIC,
  TOKEN_TYPE_HEALTH,
  TOKEN_TYPE_ITERATION,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_REVIEWER,
  TOKEN_TYPE_WEIGHT,
];

const isWildcardValue = (tokenType, value) =>
  wildcardTokens.includes(tokenType) && wildcardFilterValues.includes(value);

const requiresUpperCaseValue = (tokenType, value) =>
  tokenType === TOKEN_TYPE_TYPE || isWildcardValue(tokenType, value);

const formatData = (token) => {
  if (requiresUpperCaseValue(token.type, token.value.data)) {
    return token.value.data.toUpperCase();
  }
  if ([TOKEN_TYPE_CONFIDENTIAL, TOKEN_TYPE_DRAFT].includes(token.type)) {
    return token.value.data === 'yes';
  }

  return token.value.data;
};

function fullIterationCadenceId(id) {
  if (!id) {
    return null;
  }

  return convertToGraphQLId(TYPENAME_ITERATIONS_CADENCE, getIdFromGraphQLId(id));
}

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
    if (isIterationCadenceIdParam(token.type, token.value.data)) {
      const [iteration, cadence] = data.split('&');
      const cadenceId = fullIterationCadenceId(cadence);
      const iterationWildCardId = iteration.toUpperCase();
      obj.set(apiField, obj.has(apiField) ? [obj.get(apiField), cadenceId].flat() : cadenceId);
      const secondApiField = filtersMap[token.type][API_PARAM][WILDCARD_FILTER];
      obj.set(
        secondApiField,
        obj.has(secondApiField)
          ? [obj.get(secondApiField), iterationWildCardId].flat()
          : iterationWildCardId,
      );
    } else {
      obj.set(apiField, obj.has(apiField) ? [obj.get(apiField), data].flat() : data);
    }
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

export function findWidget(type, workItem) {
  return workItem?.widgets?.find((widget) => widget.type === type);
}

export function mapWorkItemWidgetsToIssuableFields({
  list,
  workItem,
  isBoard = false,
  namespace = BoardType.project,
  type,
}) {
  const listType = `${type}s`;

  return produce(list, (draftData) => {
    const activeList = isBoard
      ? draftData[namespace].board.lists.nodes[0][listType].nodes
      : draftData[namespace][listType].nodes;

    const activeItem = activeList.find((item) =>
      type === TYPE_EPIC
        ? item.iid === workItem.iid
        : getIdFromGraphQLId(item.id) === getIdFromGraphQLId(workItem.id),
    );

    Object.keys(WORK_ITEM_TO_ISSUABLE_MAP).forEach((widgetType) => {
      const currentWidget = findWidget(widgetType, workItem);
      if (!currentWidget) {
        return;
      }
      const property = WORK_ITEM_TO_ISSUABLE_MAP[widgetType];

      // handling the case for assignees and labels
      if (
        property === WORK_ITEM_TO_ISSUABLE_MAP[WIDGET_TYPE_ASSIGNEES] ||
        property === WORK_ITEM_TO_ISSUABLE_MAP[WIDGET_TYPE_LABELS]
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
      if (
        property === WORK_ITEM_TO_ISSUABLE_MAP[WIDGET_TYPE_MILESTONE] &&
        currentWidget[property]
      ) {
        activeItem[property] = { __persist: true, ...currentWidget[property] };
        return;
      }
      activeItem[property] = currentWidget[property];
    });

    activeItem.title = workItem.title;
    activeItem.confidential = workItem.confidential;
    activeItem.type = workItem?.workItemType?.name?.toUpperCase();
  });
}

export function updateUpvotesCount({ list, workItem, namespace = BoardType.project }) {
  const type = WIDGET_TYPE_AWARD_EMOJI;
  const property = WORK_ITEM_TO_ISSUABLE_MAP[type];

  return produce(list, (draftData) => {
    const activeItem = draftData[namespace].issues.nodes.find(
      (issue) => issue.iid === workItem.iid,
    );

    const currentWidget = findWidget(type, workItem);
    if (!currentWidget) {
      return;
    }

    const upvotesCount =
      currentWidget[property].nodes.filter((emoji) => emoji.name === EMOJI_THUMBS_UP)?.length ?? 0;
    const downvotesCount =
      currentWidget[property].nodes.filter((emoji) => emoji.name === EMOJI_THUMBS_DOWN)?.length ??
      0;
    activeItem.upvotes = upvotesCount;
    activeItem.downvotes = downvotesCount;
  });
}
