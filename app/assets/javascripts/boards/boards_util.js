import ListIssue from 'ee_else_ce/boards/models/issue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

export function getMilestone() {
  return null;
}

export function formatListIssues(listIssues) {
  const issues = {};

  const listData = listIssues.nodes.reduce((map, list) => {
    return {
      ...map,
      [list.id]: list.issues.nodes.map(i => {
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

export default {
  getMilestone,
  formatListIssues,
};
