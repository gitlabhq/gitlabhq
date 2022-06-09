export const color = {
  color: '#217645',
  title: 'Green',
};

export const colorQueryResponse = {
  data: {
    workspace: {
      id: 'gid://gitlab/Workspace/1',
      issuable: {
        __typename: 'Epic',
        id: 'gid://gitlab/Epic/1',
        color: '#217645',
      },
    },
  },
};

export const updateColorMutationResponse = {
  data: {
    updateIssuableColor: {
      issuable: {
        __typename: 'Epic',
        id: 'gid://gitlab/Epic/1',
        color: '#217645',
      },
      errors: [],
    },
  },
};
