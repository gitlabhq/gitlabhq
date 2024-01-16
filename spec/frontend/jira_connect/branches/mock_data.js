export const mockBranchNames = ['main', 'f-test', 'release'];
export const mockBranchNames2 = ['dev', 'dev-1', 'dev-2'];

export const mockProjects = [
  {
    id: 'test',
    name: 'test',
    nameWithNamespace: 'test',
    avatarUrl: 'https://gitlab.com',
    path: 'test-path',
    fullPath: 'test-path',
    repository: {
      empty: false,
    },
    userPermissions: {
      pushCode: true,
    },
  },
  {
    id: 'gitlab',
    name: 'GitLab',
    nameWithNamespace: 'gitlab-org/gitlab',
    avatarUrl: 'https://gitlab.com',
    path: 'gitlab',
    fullPath: 'gitlab-org/gitlab',
    repository: {
      empty: false,
    },
    userPermissions: {
      pushCode: true,
    },
  },
];
export const mockProjects2 = [
  {
    id: 'gitlab-test',
    name: 'gitlab-test',
    nameWithNamespace: 'gitlab-test',
    avatarUrl: 'https://gitlab.com',
    path: 'gitlab-test-path',
    fullPath: 'gitlab-test-path',
    repository: {
      empty: false,
    },
    userPermissions: {
      pushCode: true,
    },
  },
  {
    id: 'gitlab-shell',
    name: 'GitLab Shell',
    nameWithNamespace: 'gitlab-org/gitlab-shell',
    avatarUrl: 'https://gitlab.com',
    path: 'gitlab-shell',
    fullPath: 'gitlab-org/gitlab-shell',
    repository: {
      empty: false,
    },
    userPermissions: {
      pushCode: true,
    },
  },
];

export const mockProjectQueryResponse = (branchNames = mockBranchNames) => ({
  data: {
    project: {
      id: 'gid://gitlab/Project/27',
      repository: {
        branchNames,
        rootRef: 'main',
      },
    },
  },
});
