import { sortBy, cloneDeep, find, inRange } from 'lodash';
import {
  TYPENAME_BOARD,
  TYPENAME_ITERATION,
  TYPENAME_MILESTONE,
  TYPENAME_USER,
} from '~/graphql_shared/constants';
import { isGid, convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import {
  ListType,
  MilestoneIDs,
  AssigneeFilterType,
  MilestoneFilterType,
  boardQuery,
} from 'ee_else_ce/boards/constants';

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

export function calculateNewPosition(listPosition, initialPosition, targetPosition) {
  if (
    listPosition === null ||
    !(inRange(listPosition, initialPosition, targetPosition) || listPosition === targetPosition)
  ) {
    return listPosition;
  }
  const offset = initialPosition < targetPosition ? -1 : 1;
  return listPosition + offset;
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

  const listData = listIssues.nodes.reduce((map, list) => {
    let sortedIssues = list.issues.nodes;
    if (list.listType !== ListType.closed) {
      sortedIssues = sortBy(sortedIssues, 'relativePosition');
    }

    return {
      ...map,
      [list.id]: sortedIssues.map((i) => {
        const { id } = i;

        const listIssue = {
          ...i,
          labels: i.labels?.nodes || [],
          assignees: i.assignees?.nodes || [],
        };

        boardItems[id] = listIssue;

        return id;
      }),
    };
  }, {});

  return { listData, boardItems };
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
  if (!boardId) {
    return null;
  }
  return convertToGraphQLId(TYPENAME_BOARD, boardId);
}

export function fullIterationId(id) {
  return convertToGraphQLId(TYPENAME_ITERATION, id);
}

export function fullUserId(id) {
  return convertToGraphQLId(TYPENAME_USER, id);
}

export function fullMilestoneId(id) {
  return convertToGraphQLId(TYPENAME_MILESTONE, id);
}

export function fullLabelId(label) {
  if (isGid(label.id)) {
    return label.id;
  }
  if (label.project_id && label.project_id !== null) {
    return `gid://gitlab/ProjectLabel/${label.id}`;
  }
  return `gid://gitlab/GroupLabel/${label.id}`;
}

export function formatIssueInput(issueInput, boardConfig) {
  const { labelIds = [], assigneeIds = [] } = issueInput;
  const { labels, assigneeId, milestoneId, weight } = boardConfig;

  return {
    ...issueInput,
    milestoneId:
      milestoneId && milestoneId !== MilestoneIDs.ANY
        ? fullMilestoneId(milestoneId)
        : issueInput?.milestoneId,
    labelIds: [...labelIds, ...(labels?.map((l) => fullLabelId(l)) || [])],
    assigneeIds: [...assigneeIds, ...(assigneeId ? [fullUserId(assigneeId)] : [])],
    weight: weight > -1 ? weight : undefined,
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
  const updatedItem = cloneDeep(item);

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

export function moveItemVariables({
  iid,
  itemId,
  epicId = null,
  fromListId,
  toListId,
  moveBeforeId,
  moveAfterId,
  isIssue,
  boardId,
  itemToMove,
}) {
  if (isIssue) {
    return {
      iid,
      boardId,
      projectPath: itemToMove.referencePath.split(/[#]/)[0],
      moveBeforeId: moveBeforeId ? getIdFromGraphQLId(moveBeforeId) : undefined,
      moveAfterId: moveAfterId ? getIdFromGraphQLId(moveAfterId) : undefined,
      fromListId: getIdFromGraphQLId(fromListId),
      toListId: getIdFromGraphQLId(toListId),
    };
  }
  return {
    itemId,
    epicId,
    boardId,
    moveBeforeId,
    moveAfterId,
    fromListId,
    toListId,
  };
}

export function isListDraggable(list) {
  return list.listType !== ListType.backlog && list.listType !== ListType.closed;
}

export const FiltersInfo = {
  assigneeUsername: {
    negatedSupport: true,
    remap: (k, v) => (v === AssigneeFilterType.any ? 'assigneeWildcardId' : k),
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
    remap: (k, v) => (Object.values(MilestoneFilterType).includes(v) ? 'milestoneWildcardId' : k),
  },
  milestoneWildcardId: {
    negatedSupport: true,
    transform: (val) => val.toUpperCase(),
  },
  myReactionEmoji: {
    negatedSupport: true,
  },
  releaseTag: {
    negatedSupport: true,
  },
  types: {
    negatedSupport: true,
  },
  confidential: {
    negatedSupport: false,
    transform: (val) => val === 'yes',
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

export function getBoardQuery(boardType) {
  return boardQuery[boardType].query;
}

export function getListByTypeId(lists, type, id) {
  // type can be assignee/label/milestone/iteration
  if (type && id) return find(lists, (l) => l.listType === ListType[type] && l[type]?.id === id);

  return null;
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
