const defaultPageInfo = {
  hasNextPage: false,
  hasPreviousPage: false,
  startCursor: null,
  endCursor: null,
};

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

const mockApolloResponse = ({ hasNextPage = false, key, data }) => ({
  data: {
    [key]: {
      pageInfo: { ...defaultPageInfo, hasNextPage },
      nodes: data,
    },
  },
});

export const mockQueryResponse = ({
  key,
  data = [],
  loading = false,
  hasNextPage = false,
  additionalData = [],
}) => {
  const response = mockApolloResponse({ hasNextPage, key, data });
  if (loading) {
    return jest.fn().mockReturnValue(new Promise(() => {}));
  }
  if (hasNextPage) {
    return jest
      .fn()
      .mockResolvedValueOnce(response)
      .mockResolvedValueOnce(
        mockApolloResponse({
          hasNextPage: false,
          key,
          data: additionalData,
        }),
      );
  }
  return jest.fn().mockResolvedValue(response);
};
