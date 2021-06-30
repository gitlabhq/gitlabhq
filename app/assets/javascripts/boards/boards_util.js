import { sortBy, cloneDeep } from 'lodash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { ListType } from './constants';

export function getMilestone() {
  return null;
}

export function updateListPosition(listObj) {
  const { listType } = listObj;
  let { position } = listObj;
  if (listType === ListType.closed) {
    position = Infinity;
  } else if (listType === ListType.backlog) {
    position = -Infinity;
  }

  return { ...listObj, position };
}

export function formatBoardLists(lists) {
  return lists.nodes.reduce((map, list) => {
    return {
      ...map,
      [list.id]: updateListPosition(list),
    };
  }, {});
}

export function formatIssue(issue) {
  return {
    ...issue,
    labels: issue.labels?.nodes || [],
    assignees: issue.assignees?.nodes || [],
  };
}

export function formatListIssues(listIssues) {
  const boardItems = {};
  let listItemsCount;

  const listData = listIssues.nodes.reduce((map, list) => {
    listItemsCount = list.issuesCount;
    let sortedIssues = list.issues.edges.map((issueNode) => ({
      ...issueNode.node,
    }));
    sortedIssues = sortBy(sortedIssues, 'relativePosition');

    return {
      ...map,
      [list.id]: sortedIssues.map((i) => {
        const id = getIdFromGraphQLId(i.id);

        const listIssue = {
          ...i,
          id,
          fullId: i.id,
          labels: i.labels?.nodes || [],
          assignees: i.assignees?.nodes || [],
        };

        boardItems[id] = listIssue;

        return id;
      }),
    };
  }, {});

  return { listData, boardItems, listItemsCount };
}

export function formatListsPageInfo(lists) {
  const listData = lists.nodes.reduce((map, list) => {
    return {
      ...map,
      [list.id]: list.issues.pageInfo,
    };
  }, {});
  return listData;
}

export function fullBoardId(boardId) {
  return `gid://gitlab/Board/${boardId}`;
}

export function fullIterationId(id) {
  return `gid://gitlab/Iteration/${id}`;
}

export function fullUserId(id) {
  return `gid://gitlab/User/${id}`;
}

export function fullMilestoneId(id) {
  return `gid://gitlab/Milestone/${id}`;
}

export function fullLabelId(label) {
  if (label.project_id && label.project_id !== null) {
    return `gid://gitlab/ProjectLabel/${label.id}`;
  }
  return `gid://gitlab/GroupLabel/${label.id}`;
}

export function formatIssueInput(issueInput, boardConfig) {
  const { labelIds = [], assigneeIds = [] } = issueInput;
  const { labels, assigneeId, milestoneId } = boardConfig;

  return {
    milestoneId: milestoneId ? fullMilestoneId(milestoneId) : null,
    ...issueInput,
    labelIds: [...labelIds, ...(labels?.map((l) => fullLabelId(l)) || [])],
    assigneeIds: [...assigneeIds, ...(assigneeId ? [fullUserId(assigneeId)] : [])],
  };
}

export function shouldCloneCard(fromListType, toListType) {
  const involvesClosed = fromListType === ListType.closed || toListType === ListType.closed;
  const involvesBacklog = fromListType === ListType.backlog || toListType === ListType.backlog;

  if (involvesClosed || involvesBacklog) {
    return false;
  }

  if (fromListType !== toListType) {
    return true;
  }

  return false;
}

export function getMoveData(state, params) {
  const { boardItems, boardItemsByListId, boardLists } = state;
  const { itemId, fromListId, toListId } = params;
  const fromListType = boardLists[fromListId].listType;
  const toListType = boardLists[toListId].listType;

  return {
    reordering: fromListId === toListId,
    shouldClone: shouldCloneCard(fromListType, toListType),
    itemNotInToList: !boardItemsByListId[toListId].includes(itemId),
    originalIssue: cloneDeep(boardItems[itemId]),
    originalIndex: boardItemsByListId[fromListId].indexOf(itemId),
    ...params,
  };
}

export function moveItemListHelper(item, fromList, toList) {
  const updatedItem = item;
  if (
    toList.listType === ListType.label &&
    !updatedItem.labels.find((label) => label.id === toList.label.id)
  ) {
    updatedItem.labels.push(toList.label);
  }
  if (fromList?.label && fromList.listType === ListType.label) {
    updatedItem.labels = updatedItem.labels.filter((label) => fromList.label.id !== label.id);
  }

  if (
    toList.listType === ListType.assignee &&
    !updatedItem.assignees.find((assignee) => assignee.id === toList.assignee.id)
  ) {
    updatedItem.assignees.push(toList.assignee);
  }
  if (fromList?.assignee && fromList.listType === ListType.assignee) {
    updatedItem.assignees = updatedItem.assignees.filter(
      (assignee) => assignee.id !== fromList.assignee.id,
    );
  }

  return updatedItem;
}

export function isListDraggable(list) {
  return list.listType !== ListType.backlog && list.listType !== ListType.closed;
}

export const FiltersInfo = {
  assigneeUsername: {
    negatedSupport: true,
  },
  assigneeId: {
    // assigneeId should be renamed to assigneeWildcardId.
    // Classic boards used 'assigneeId'
    remap: () => 'assigneeWildcardId',
  },
  assigneeWildcardId: {
    negatedSupport: false,
    transform: (val) => val.toUpperCase(),
  },
  authorUsername: {
    negatedSupport: true,
  },
  labelName: {
    negatedSupport: true,
  },
  milestoneTitle: {
    negatedSupport: true,
  },
  myReactionEmoji: {
    negatedSupport: true,
  },
  releaseTag: {
    negatedSupport: true,
  },
  search: {
    negatedSupport: false,
  },
};

/**
 * @param {Object} filters - ex. { search: "foobar", "not[authorUsername]": "root", }
 * @returns {Object} - ex. [ ["search", "foobar", false], ["authorUsername", "root", true], ]
 */
const parseFilters = (filters) => {
  /* eslint-disable-next-line @gitlab/require-i18n-strings */
  const isNegated = (x) => x.startsWith('not[') && x.endsWith(']');

  return Object.entries(filters).map(([k, v]) => {
    const isNot = isNegated(k);
    const filterKey = isNot ? k.slice(4, -1) : k;

    return [filterKey, v, isNot];
  });
};

/**
 * Returns an object of filter key/value pairs used as variables in GraphQL requests.
 * (warning: filter values are not validated)
 *
 * @param {Object} objParam.filters - filters extracted from url params. ex. { search: "foobar", "not[authorUsername]": "root", }
 * @param {string} objParam.issuableType - issuable type e.g., issue.
 * @param {Object} objParam.filterInfo - data on filters such as how to transform filter value, if filter can be negated, etc.
 * @param {Object} objParam.filterFields - data on what filters are available for given issuableType (based on GraphQL schema)
 */
export const filterVariables = ({ filters, issuableType, filterInfo, filterFields }) =>
  parseFilters(filters)
    .map(([k, v, negated]) => {
      // for legacy reasons, some filters need to be renamed to correct GraphQL fields.
      const remapAvailable = filterInfo[k]?.remap;
      const remappedKey = remapAvailable ? filterInfo[k].remap(k, v) : k;

      return [remappedKey, v, negated];
    })
    .filter(([k, , negated]) => {
      // remove unsupported filters (+ check if the filters support negation)
      const supported = filterFields[issuableType].includes(k);
      if (supported) {
        return negated ? filterInfo[k].negatedSupport : true;
      }

      return false;
    })
    .map(([k, v, negated]) => {
      // if the filter value needs a special transformation, apply it (e.g., capitalization)
      const transform = filterInfo[k]?.transform;
      const newVal = transform ? transform(v) : v;

      return [k, newVal, negated];
    })
    .reduce(
      (acc, [k, v, negated]) => {
        return negated
          ? {
              ...acc,
              not: {
                ...acc.not,
                [k]: v,
              },
            }
          : {
              ...acc,
              [k]: v,
            };
      },
      { not: {} },
    );

// EE-specific feature. Find the implementation in the `ee/`-folder
export function transformBoardConfig() {
  return '';
}

export default {
  getMilestone,
  formatIssue,
  formatListIssues,
  fullBoardId,
  fullLabelId,
  fullIterationId,
  isListDraggable,
};
