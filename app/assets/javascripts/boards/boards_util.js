import { sortBy } from 'lodash';
import { ListType } from './constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import boardsStore from '~/boards/stores/boards_store';

export function getMilestone() {
  return null;
}

export function formatBoardLists(lists) {
  const formattedLists = lists.nodes.map(list =>
    boardsStore.updateListPosition({ ...list, doNotFetchIssues: true }),
  );
  return formattedLists.reduce((map, list) => {
    return {
      ...map,
      [list.id]: list,
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
  const issues = {};
  let listIssuesCount;

  const listData = listIssues.nodes.reduce((map, list) => {
    listIssuesCount = list.issues.count;
    let sortedIssues = list.issues.edges.map(issueNode => ({
      ...issueNode.node,
    }));
    sortedIssues = sortBy(sortedIssues, 'relativePosition');

    return {
      ...map,
      [list.id]: sortedIssues.map(i => {
        const id = getIdFromGraphQLId(i.id);

        const listIssue = {
          ...i,
          id,
          labels: i.labels?.nodes || [],
          assignees: i.assignees?.nodes || [],
        };

        issues[id] = listIssue;

        return id;
      }),
    };
  }, {});

  return { listData, issues, listIssuesCount };
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

export function fullLabelId(label) {
  if (label.project_id !== null) {
    return `gid://gitlab/ProjectLabel/${label.id}`;
  }
  return `gid://gitlab/GroupLabel/${label.id}`;
}

export function moveIssueListHelper(issue, fromList, toList) {
  const updatedIssue = issue;
  if (
    toList.type === ListType.label &&
    !updatedIssue.labels.find(label => label.id === toList.label.id)
  ) {
    updatedIssue.labels.push(toList.label);
  }
  if (fromList?.label && fromList.type === ListType.label) {
    updatedIssue.labels = updatedIssue.labels.filter(label => fromList.label.id !== label.id);
  }

  if (
    toList.type === ListType.assignee &&
    !updatedIssue.assignees.find(assignee => assignee.id === toList.assignee.id)
  ) {
    updatedIssue.assignees.push(toList.assignee);
  }
  if (fromList?.assignee && fromList.type === ListType.assignee) {
    updatedIssue.assignees = updatedIssue.assignees.filter(
      assignee => assignee.id !== fromList.assignee.id,
    );
  }

  return updatedIssue;
}

export default {
  getMilestone,
  formatIssue,
  formatListIssues,
  fullBoardId,
  fullLabelId,
};
