import { sortBy } from 'lodash';
import ListIssue from 'ee_else_ce/boards/models/issue';
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
  return new ListIssue({
    ...issue,
    labels: issue.labels?.nodes || [],
    assignees: issue.assignees?.nodes || [],
  });
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

        const listIssue = new ListIssue({
          ...i,
          id,
          labels: i.labels?.nodes || [],
          assignees: i.assignees?.nodes || [],
        });

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
  if (toList.type === ListType.label) {
    issue.addLabel(toList.label);
  }
  if (fromList && fromList.type === ListType.label) {
    issue.removeLabel(fromList.label);
  }

  if (toList.type === ListType.assignee) {
    issue.addAssignee(toList.assignee);
  }
  if (fromList && fromList.type === ListType.assignee) {
    issue.removeAssignee(fromList.assignee);
  }

  return issue;
}

export default {
  getMilestone,
  formatIssue,
  formatListIssues,
  fullBoardId,
  fullLabelId,
};
