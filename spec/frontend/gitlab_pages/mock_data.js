export const primaryDeployment = {
  id: 'gid://gitlab/PagesDeployment/1',
  active: true,
  pathPrefix: null,
  url: 'https://example.com',
  createdAt: '2023-04-01T12:00:00Z',
  ciBuildId: 123,
  rootDirectory: 'foo/bar',
  fileCount: 100,
  size: 1024,
  updatedAt: '2023-04-02T12:05:00Z',
  deletedAt: null,
};

export const environmentDeployment = {
  ...primaryDeployment,
  pathPrefix: '_stg',
  expiresAt: '2023-04-02T12:00:00Z',
};

export const deleteDeploymentResult = {
  deletePagesDeployment: {
    errors: [],
    pagesDeployment: {
      id: 1,
      active: false,
      deletedAt: '2023-04-02T12:10:00Z',
      updatedAt: '2023-04-02T12:10:00Z',
    },
  },
};

export const restoreDeploymentResult = {
  restorePagesDeployment: {
    errors: [],
    pagesDeployment: {
      id: 1,
      active: true,
      deletedAt: null,
      updatedAt: '2023-04-02T12:15:00Z',
    },
  },
};
