import groupBoardMembers from '~/boards/graphql/group_board_members.query.graphql';
import projectBoardMembers from '~/boards/graphql/project_board_members.query.graphql';
import { BoardType } from './constants';
import boardLabels from './graphql/board_labels.query.graphql';

export default function issueBoardFilters(apollo, fullPath, boardType) {
  const isGroupBoard = boardType === BoardType.group;
  const isProjectBoard = boardType === BoardType.project;
  const transformLabels = ({ data }) => {
    return isGroupBoard ? data.group?.labels.nodes || [] : data.project?.labels.nodes || [];
  };

  const boardAssigneesQuery = () => {
    return isGroupBoard ? groupBoardMembers : projectBoardMembers;
  };

  const fetchAuthors = (authorsSearchTerm) => {
    return apollo
      .query({
        query: boardAssigneesQuery(),
        variables: {
          fullPath,
          search: authorsSearchTerm,
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
          isProject: isProjectBoard,
        },
      })
      .then(transformLabels);
  };

  return {
    fetchLabels,
    fetchAuthors,
  };
}
