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

const mockMergeRequests = [
  {
    id: '111',
    iid: '123',
    title: 'MR 1',
    createdAt: '2020-07-07T00:00:00Z',
    author: { name: 'root' },
    webUrl: 'https://gitlab.com/root/project/-/merge_requests/123',
    assignees: { nodes: [{ name: 'root' }] },
    project: {
      id: '1',
      fullPath: 'full/path/to/project',
    },
    sourceBranch: 'main',
  },
  {
    id: '222',
    iid: '456',
    title: 'MR 2',
    createdAt: '2020-07-09T00:00:00Z',
    author: { name: 'homer' },
    webUrl: 'https://gitlab.com/homer/project/-/merge_requests/456',
    assignees: { nodes: [{ name: 'homer' }] },
    project: {
      id: '1',
      fullPath: 'full/path/to/project',
    },
    sourceBranch: 'main',
  },
];

export const openMRsDetailResult = jest.fn().mockResolvedValue({
  data: {
    project: {
      id: '1',
      mergeRequests: {
        nodes: mockMergeRequests,
        count: 2,
      },
    },
  },
});
