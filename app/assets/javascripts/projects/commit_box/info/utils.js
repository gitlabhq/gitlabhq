export const formatStages = (graphQLStages = [], restStages = []) => {
  if (graphQLStages.length !== restStages.length) {
    throw new Error('Rest stages and graphQl stages must be the same length');
  }

  return graphQLStages.map((stage, index) => {
    return {
      name: stage.name,
      status: stage.detailedStatus,
      dropdown_path: restStages[index]?.dropdown_path || '',
      title: restStages[index].title || '',
    };
  });
};
