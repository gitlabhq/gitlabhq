export const createCommitMutationResult = {
  data: {
    commitCreate: {
      commit: {
        id: '82a9df1',
      },
      content: 'foo: bar',
      errors: null,
    },
  },
};

export const createCommitMutationErrorResult = {
  data: {
    commitCreate: {
      commit: null,
      content: null,
      errors: ['Some Error Message'],
    },
  },
};

export const fileQueryResult = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      repository: {
        blobs: {
          nodes: [
            {
              id: 'gid://gitlab/Blob/9ff96777b315cd37188f7194d8382c718cb2933c',
            },
          ],
        },
      },
    },
  },
};

export const fileQueryEmptyResult = {
  data: {
    project: {
      id: 'gid://gitlab/Project/2',
      repository: {
        blobs: {
          nodes: [],
        },
      },
    },
  },
};

export const fileQueryErrorResult = {
  data: {
    foo: 'bar',
    project: {
      id: null,
      repository: null,
    },
  },
  errors: [{ message: 'GraphQL Error' }],
};
