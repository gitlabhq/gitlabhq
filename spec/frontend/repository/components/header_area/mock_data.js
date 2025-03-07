export const openMRQueryResult = jest.fn().mockResolvedValue({
  data: {
    project: {
      __typename: 'Project',
      id: '1234',
      mergeRequests: {
        count: 3,
      },
    },
  },
});

export const zeroOpenMRQueryResult = jest.fn().mockResolvedValue({
  data: {
    project: {
      __typename: 'Project',
      id: '1234',
      mergeRequests: {
        count: 0,
      },
    },
  },
});
