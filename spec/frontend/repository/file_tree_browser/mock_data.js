export const mockResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/19',
      __typename: 'Project',
      repository: {
        __typename: 'Repository',
        paginatedTree: {
          __typename: 'TreeConnection',
          nodes: [
            {
              __typename: 'Tree',
              trees: {
                __typename: 'TreeEntryConnection',
                nodes: [
                  {
                    __typename: 'TreeEntry',
                    id: 'gid://123',
                    sha: '9b5feb87b3c6f6fa0a4ee976a31e1c311dd8da81',
                    name: 'dir_2',
                    flatPath: 'dir_1/dir_2',
                    type: 'tree',
                    path: 'dir_1/dir_2',
                    webPath: '/root/jerasmus-test-project/-/tree/master/dir_1/dir_2',
                  },
                ],
              },
              submodules: {
                __typename: 'SubmoduleConnection',
                nodes: [],
              },
              blobs: {
                __typename: 'BlobConnection',
                nodes: [
                  {
                    __typename: 'Blob',
                    id: 'gid://456',
                    sha: 'abc123',
                    name: 'file.txt',
                    path: 'dir_1/file.txt',
                    mode: '100644',
                    webPath: '/root/jerasmus-test-project/-/blob/master/dir_1/file.txt',
                  },
                ],
              },
            },
          ],
        },
      },
    },
  },
};
