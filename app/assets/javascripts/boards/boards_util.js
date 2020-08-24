import ListIssue from 'ee_else_ce/boards/models/issue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

export function getMilestone() {
  return null;
}

export function formatListIssues(listIssues) {
  return listIssues.nodes.reduce((map, list) => {
    return {
      ...map,
      [list.id]: list.issues.nodes.map(
        i =>
          new ListIssue({
            ...i,
            id: getIdFromGraphQLId(i.id),
            labels: i.labels?.nodes || [],
            assignees: i.assignees?.nodes || [],
          }),
      ),
    };
  }, {});
}

export function fullBoardId(boardId) {
  return `gid://gitlab/Board/${boardId}`;
}

export default {
  getMilestone,
  formatListIssues,
};
