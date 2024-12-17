export const pageInfoHeadersWithoutPagination = {
  'X-NEXT-PAGE': '',
  'X-PAGE': '1',
  'X-PER-PAGE': '20',
  'X-PREV-PAGE': '',
  'X-TOTAL': '19',
  'X-TOTAL-PAGES': '1',
};

export const pageInfoHeadersWithPagination = {
  'X-NEXT-PAGE': '2',
  'X-PAGE': '1',
  'X-PER-PAGE': '20',
  'X-PREV-PAGE': '',
  'X-TOTAL': '21',
  'X-TOTAL-PAGES': '2',
};

export const generateCatalogSettingsResponse = (isCatalogResource = false) => {
  return {
    data: {
      project: {
        id: 'gid://gitlab/Project/149',
        isCatalogResource,
      },
    },
  };
};

export const catalogReleasesResponse = {
  data: {
    ciCatalogResource: {
      id: 'gid://gitlab/Ci::Catalog::Resource/39',
      versions: {
        nodes: [
          {
            id: 'gid://gitlab/Ci::Catalog::Resources::Version/13',
            path: '/root/project/-/tags/1.0.7',
            __typename: 'CiCatalogResourceVersion',
          },
          {
            id: 'gid://gitlab/Ci::Catalog::Resources::Version/12',
            path: '/root/project/-/tags/1.0.6',
            __typename: 'CiCatalogResourceVersion',
          },
        ],
        __typename: 'CiCatalogResourceVersionConnection',
      },
      __typename: 'CiCatalogResource',
    },
  },
};

export const mockDeployment = {
  environment: {
    name: 'test',
    url: 'http://test.com/group/project/-/environments/21',
  },
  status: 'Success',
  deployment: {
    id: 215,
    url: '/group/project/-/environments/21/deployments/167',
  },
  commit: {
    sha: '3d436ec78e378371610793d5cf95adcaf0c37193',
    name: 'Administrator',
    commitUrl: 'http://test.com/group/project/-/commit/3d436ec78e378371610793d5cf95adcaf0c37193',
    shortSha: '3d436ec7',
    title: 'Test commit',
  },
  triggerer: {
    name: 'Administrator',
    webUrl: 'http://test.com/root',
    avatarUrl: 'http://test.com/avatar',
  },
  createdAt: '2024-10-20T06:13:55.101Z',
  finishedAt: '2024-10-20T06:14:55.101Z',
};
