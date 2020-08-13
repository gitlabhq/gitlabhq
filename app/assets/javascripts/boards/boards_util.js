import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import ListIssue from 'ee_else_ce/boards/models/issue';

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

export default {
  getMilestone,
  formatListIssues,
};
