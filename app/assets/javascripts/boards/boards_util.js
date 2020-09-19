import { sortBy } from 'lodash';
import ListIssue from 'ee_else_ce/boards/models/issue';
import { ListType } from './constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

export function getMilestone() {
  return null;
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

  const listData = listIssues.nodes.reduce((map, list) => {
    const sortedIssues = sortBy(list.issues.nodes, 'relativePosition');
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

  return { listData, issues };
}

export function fullBoardId(boardId) {
  return `gid://gitlab/Board/${boardId}`;
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
};
