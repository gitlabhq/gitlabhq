export const BLAME_DATA_QUERY_RESPONSE_MOCK = {
  data: {
    project: {
      id: 'gid://gitlab/Project/278964',
      __typename: 'Project',
      repository: {
        __typename: 'Repository',
        blobs: {
          __typename: 'BlobConnection',
          nodes: [
            {
              id: 'gid://gitlab/Blob/f0c77e4b621df72719ce2b500ea6228559f6bc09',
              blame: {
                firstLine: '1',
                groups: [
                  {
                    lineno: 1,
                    span: 3,
                    blameOffset: '0px',
                    commit: {
                      id: 'gid://gitlab/CommitPresenter/13b0aca4142d1d55931577f69289a792f216f805',
                      titleHtml: 'Upload New File',
                      message: 'Upload New File',
                      authoredDate: '2022-10-31T10:38:30+00:00',
                      authorName: 'Peter',
                      authorGravatar: 'path/to/gravatar',
                      webPath: '/commit/1234',
                      author: {},
                      sha: '13b0aca4142d1d55931577f69289a792f216f805',
                    },
                    commitData: { projectBlameLink: 'project/blame/link' },
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
