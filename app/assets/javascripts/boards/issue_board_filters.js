import boardLabels from './graphql/board_labels.query.graphql';

export default function issueBoardFilters(apollo, fullPath, isGroupBoard) {
  const transformLabels = ({ data }) => {
    return isGroupBoard ? data.group?.labels.nodes || [] : data.project?.labels.nodes || [];
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

  return {
    fetchLabels,
  };
}
