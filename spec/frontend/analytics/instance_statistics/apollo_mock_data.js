const defaultPageInfo = { hasPreviousPage: false, startCursor: null, endCursor: null };

export function getApolloResponse(options = {}) {
  const {
    pipelinesTotal = [],
    pipelinesSucceeded = [],
    pipelinesFailed = [],
    pipelinesCanceled = [],
    pipelinesSkipped = [],
    hasNextPage = false,
  } = options;
  return {
    data: {
      pipelinesTotal: { pageInfo: { ...defaultPageInfo, hasNextPage }, nodes: pipelinesTotal },
      pipelinesSucceeded: {
        pageInfo: { ...defaultPageInfo, hasNextPage },
        nodes: pipelinesSucceeded,
      },
      pipelinesFailed: { pageInfo: { ...defaultPageInfo, hasNextPage }, nodes: pipelinesFailed },
      pipelinesCanceled: {
        pageInfo: { ...defaultPageInfo, hasNextPage },
        nodes: pipelinesCanceled,
      },
      pipelinesSkipped: {
        pageInfo: { ...defaultPageInfo, hasNextPage },
        nodes: pipelinesSkipped,
      },
    },
  };
}
