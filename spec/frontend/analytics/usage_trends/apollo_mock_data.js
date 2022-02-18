const defaultPageInfo = {
  __typename: 'PageInfo',
  hasNextPage: false,
  hasPreviousPage: false,
  startCursor: null,
  endCursor: null,
};

export const mockApolloResponse = ({ hasNextPage = false, key, data }) => ({
  data: {
    [key]: {
      pageInfo: { ...defaultPageInfo, hasNextPage },
      nodes: data,
    },
  },
});

export const mockQueryResponse = ({ key, data = [], loading = false, additionalData = [] }) => {
  const hasNextPage = Boolean(additionalData.length);
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
