const createMergeRequestPipelines = (count = 30) => {
  const pipelines = [];

  for (let i = 0; i < count; i += 1) {
    pipelines.push({
      id: i,
      iid: i + 10,
      path: `/project/pipelines/${i}`,
    });
  }

  return {
    count,
    nodes: pipelines,
  };
};

export const mergeRequestPipelinesResponse = {
  data: {
    project: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/1',
      mergeRequest: {
        __typename: 'MergeRequest',
        id: 'gid://gitlab/MergeRequest/1',
        pipelines: createMergeRequestPipelines(),
      },
    },
  },
};
