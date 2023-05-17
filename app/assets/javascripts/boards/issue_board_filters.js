import groupBoardMembers from '~/boards/graphql/group_board_members.query.graphql';
import projectBoardMembers from '~/boards/graphql/project_board_members.query.graphql';
import groupBoardMilestonesQuery from './graphql/group_board_milestones.query.graphql';
import projectBoardMilestonesQuery from './graphql/project_board_milestones.query.graphql';
import boardLabels from './graphql/board_labels.query.graphql';

export default function issueBoardFilters(apollo, fullPath, isGroupBoard) {
  const transformLabels = ({ data }) => {
    return isGroupBoard ? data.group?.labels.nodes || [] : data.project?.labels.nodes || [];
  };

  const boardAssigneesQuery = () => {
    return isGroupBoard ? groupBoardMembers : projectBoardMembers;
  };

  const fetchUsers = (usersSearchTerm) => {
    return apollo
      .query({
        query: boardAssigneesQuery(),
        variables: {
          fullPath,
          search: usersSearchTerm,
        },
      })
      .then(({ data }) => data.workspace?.assignees.nodes.map(({ user }) => user));
  };

  const fetchLabels = (labelSearchTerm) => {
    return apollo
      .query({
        query: boardLabels,
        variables: {
          fullPath,
          searchTerm: labelSearchTerm,
          isGroup: isGroupBoard,
          isProject: !isGroupBoard,
        },
      })
      .then(transformLabels);
  };

  const fetchMilestones = (searchTerm) => {
    const variables = {
      fullPath,
      searchTerm,
    };

    const query = isGroupBoard ? groupBoardMilestonesQuery : projectBoardMilestonesQuery;

    return apollo
      .query({
        query,
        variables,
      })
      .then(({ data }) => {
        return data.workspace?.milestones.nodes;
      });
  };

  return {
    fetchLabels,
    fetchUsers,
    fetchMilestones,
  };
}
