import { sortBy } from 'lodash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { ListType, NOT_FILTER } from './constants';

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
    listItemsCount = list.issues.count;
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

export function transformNotFilters(filters) {
  return Object.keys(filters)
    .filter((key) => key.startsWith(NOT_FILTER))
    .reduce((obj, key) => {
      return {
        ...obj,
        [key.substring(4, key.length - 1)]: filters[key],
      };
    }, {});
}

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
  transformNotFilters,
};
