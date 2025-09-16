export const mockPermalinkResult = jest.fn().mockResolvedValue({
  data: {
    project: {
      id: '1',
      repository: {
        paginatedTree: {
          nodes: [
            {
              __typename: 'Tree',
              permalinkPath:
                '/gitlab-org/gitlab-shell/-/tree/5059017dea6e834f2f86fc670703ca36cbae98d6/cmd',
            },
          ],
          __typename: 'TreeConnection',
        },
        __typename: 'Repository',
      },
      __typename: 'Project',
    },
  },
});

export const mockRootPermalinkResult = jest.fn().mockResolvedValue({
  data: {
    project: {
      id: '2',
      repository: {
        paginatedTree: {
          nodes: [
            {
              __typename: 'Tree',
              permalinkPath:
                '/gitlab-org/gitlab-shell/-/tree/5059017dea6e834f2f86fc670703ca36cbae98d6/',
            },
          ],
          __typename: 'TreeConnection',
        },
        __typename: 'Repository',
      },
      __typename: 'Project',
    },
  },
});
