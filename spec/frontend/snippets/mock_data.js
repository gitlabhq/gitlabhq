export const getCanCreateProjectSnippetMock = (createSnippet = false) => ({
  data: {
    project: {
      userPermissions: {
        createSnippet,
      },
    },
  },
});

export const getCanCreatePersonalSnippetMock = (createSnippet = false) => ({
  data: {
    currentUser: {
      userPermissions: {
        createSnippet,
      },
    },
  },
});
