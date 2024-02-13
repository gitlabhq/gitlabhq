const mockGroupFactory = (fullPath) => ({
  id: `gid://gitlab/Group/${fullPath}`,
  fullPath,
  name: fullPath,
  projectCreationLevel: 'maintainer',
  visibility: 'public',
  webUrl: `http://gdk.test:3000/groups/${fullPath}`,
  __typename: 'Group',
});

export const mockAvailableNamespaces = [
  mockGroupFactory('match1'),
  mockGroupFactory('unrelated'),
  mockGroupFactory('match2'),
];

export const mockNamespacesResponse = {
  data: {
    currentUser: {
      id: 'gid://gitlab/User/1',
      groups: {
        nodes: mockAvailableNamespaces,
        __typename: 'GroupConnection',
      },
      namespace: {
        id: 'gid://gitlab/Namespaces::UserNamespace/1',
        fullPath: 'root',
        __typename: 'Namespace',
      },
      __typename: 'UserCore',
    },
  },
};

export const mockUserNamespace = 'user1';
