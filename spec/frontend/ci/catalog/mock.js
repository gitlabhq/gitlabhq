import { componentsMockData } from '~/ci/catalog/constants';

export const emptyCatalogResponseBody = {
  data: {
    ciCatalogResources: {
      pageInfo: {
        startCursor:
          'eyJjcmVhdGVkX2F0IjoiMjAxNS0wNy0wMyAxMDowMDowMC4wMDAwMDAwMDAgKzAwMDAiLCJpZCI6IjEyOSJ9',
        endCursor:
          'eyJjcmVhdGVkX2F0IjoiMjAxNS0wNy0wMyAxMDowMDowMC4wMDAwMDAwMDAgKzAwMDAiLCJpZCI6IjExMCJ9',
        hasNextPage: false,
        hasPreviousPage: false,
        __typename: 'PageInfo',
      },
      count: 0,
      nodes: [],
    },
  },
};

export const catalogResponseBody = {
  data: {
    ciCatalogResources: {
      pageInfo: {
        startCursor:
          'eyJjcmVhdGVkX2F0IjoiMjAxNS0wNy0wMyAxMDowMDowMC4wMDAwMDAwMDAgKzAwMDAiLCJpZCI6IjEyOSJ9',
        endCursor:
          'eyJjcmVhdGVkX2F0IjoiMjAxNS0wNy0wMyAxMDowMDowMC4wMDAwMDAwMDAgKzAwMDAiLCJpZCI6IjExMCJ9',
        hasNextPage: true,
        hasPreviousPage: false,
        __typename: 'PageInfo',
      },
      count: 41,
      nodes: [
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/129',
          icon: null,
          name: 'Project-42 Name',
          description: 'A simple component',
          starCount: 0,
          latestVersion: null,
          webPath: '/frontend-fixtures/project-42',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/128',
          icon: null,
          name: 'Project-41 Name',
          description: 'A simple component',
          starCount: 0,
          latestVersion: null,
          webPath: '/frontend-fixtures/project-41',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/127',
          icon: null,
          name: 'Project-40 Name',
          description: 'A simple component',
          starCount: 0,
          latestVersion: null,
          webPath: '/frontend-fixtures/project-40',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/126',
          icon: null,
          name: 'Project-39 Name',
          description: 'A simple component',
          starCount: 0,
          latestVersion: null,
          webPath: '/frontend-fixtures/project-39',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/125',
          icon: null,
          name: 'Project-38 Name',
          description: 'A simple component',
          starCount: 0,
          latestVersion: null,
          webPath: '/frontend-fixtures/project-38',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/124',
          icon: null,
          name: 'Project-37 Name',
          description: 'A simple component',
          starCount: 0,
          latestVersion: null,
          webPath: '/frontend-fixtures/project-37',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/123',
          icon: null,
          name: 'Project-36 Name',
          description: 'A simple component',
          starCount: 0,
          latestVersion: null,
          webPath: '/frontend-fixtures/project-36',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/122',
          icon: null,
          name: 'Project-35 Name',
          description: 'A simple component',
          starCount: 0,
          latestVersion: null,
          webPath: '/frontend-fixtures/project-35',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/121',
          icon: null,
          name: 'Project-34 Name',
          description: 'A simple component',
          starCount: 0,
          latestVersion: null,
          webPath: '/frontend-fixtures/project-34',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/120',
          icon: null,
          name: 'Project-33 Name',
          description: 'A simple component',
          starCount: 0,
          latestVersion: null,
          webPath: '/frontend-fixtures/project-33',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/119',
          icon: null,
          name: 'Project-32 Name',
          description: 'A simple component',
          starCount: 0,
          latestVersion: null,
          webPath: '/frontend-fixtures/project-32',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/118',
          icon: null,
          name: 'Project-31 Name',
          description: 'A simple component',
          starCount: 0,
          latestVersion: null,
          webPath: '/frontend-fixtures/project-31',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/117',
          icon: null,
          name: 'Project-30 Name',
          description: 'A simple component',
          starCount: 0,
          latestVersion: null,
          webPath: '/frontend-fixtures/project-30',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/116',
          icon: null,
          name: 'Project-29 Name',
          description: 'A simple component',
          starCount: 0,
          latestVersion: null,
          webPath: '/frontend-fixtures/project-29',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/115',
          icon: null,
          name: 'Project-28 Name',
          description: 'A simple component',
          starCount: 0,
          latestVersion: null,
          webPath: '/frontend-fixtures/project-28',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/114',
          icon: null,
          name: 'Project-27 Name',
          description: 'A simple component',
          starCount: 0,
          latestVersion: null,
          webPath: '/frontend-fixtures/project-27',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/113',
          icon: null,
          name: 'Project-26 Name',
          description: 'A simple component',
          starCount: 0,
          latestVersion: null,
          webPath: '/frontend-fixtures/project-26',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/112',
          icon: null,
          name: 'Project-25 Name',
          description: 'A simple component',
          starCount: 0,
          latestVersion: null,
          webPath: '/frontend-fixtures/project-25',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/111',
          icon: null,
          name: 'Project-24 Name',
          description: 'A simple component',
          starCount: 0,
          latestVersion: null,
          webPath: '/frontend-fixtures/project-24',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/110',
          icon: null,
          name: 'Project-23 Name',
          description: 'A simple component',
          starCount: 0,
          latestVersion: null,
          webPath: '/frontend-fixtures/project-23',
          __typename: 'CiCatalogResource',
        },
      ],
      __typename: 'CiCatalogResourceConnection',
    },
  },
};

export const catalogSinglePageResponse = {
  data: {
    ciCatalogResources: {
      pageInfo: {
        startCursor:
          'eyJjcmVhdGVkX2F0IjoiMjAxNS0wNy0wMyAxMDowMDowMC4wMDAwMDAwMDAgKzAwMDAiLCJpZCI6IjEzMiJ9',
        endCursor:
          'eyJjcmVhdGVkX2F0IjoiMjAxNS0wNy0wMyAxMDowMDowMC4wMDAwMDAwMDAgKzAwMDAiLCJpZCI6IjEzMCJ9',
        hasNextPage: false,
        hasPreviousPage: false,
        __typename: 'PageInfo',
      },
      count: 3,
      nodes: [
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/132',
          icon: null,
          name: 'Project-45 Name',
          description: 'A simple component',
          starCount: 0,
          latestVersion: null,
          webPath: '/frontend-fixtures/project-45',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/131',
          icon: null,
          name: 'Project-44 Name',
          description: 'A simple component',
          starCount: 0,
          latestVersion: null,
          webPath: '/frontend-fixtures/project-44',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/130',
          icon: null,
          name: 'Project-43 Name',
          description: 'A simple component',
          starCount: 0,
          latestVersion: null,
          webPath: '/frontend-fixtures/project-43',
          __typename: 'CiCatalogResource',
        },
      ],
      __typename: 'CiCatalogResourceConnection',
    },
  },
};

export const catalogSharedDataMock = {
  data: {
    ciCatalogResource: {
      __typename: 'CiCatalogResource',
      id: `gid://gitlab/CiCatalogResource/1`,
      icon: null,
      description: 'This is the description of the repo',
      name: 'Ruby',
      starCount: 1,
      latestVersion: {
        __typename: 'Release',
        id: '3',
        tagName: '1.0.0',
        tagPath: 'path/to/release',
        releasedAt: Date.now(),
        author: { id: 1, webUrl: 'profile/1', name: 'username' },
      },
      webPath: 'path/to/project',
    },
  },
};

export const catalogAdditionalDetailsMock = {
  data: {
    ciCatalogResource: {
      __typename: 'CiCatalogResource',
      id: `gid://gitlab/CiCatalogResource/1`,
      openIssuesCount: 4,
      openMergeRequestsCount: 10,
      readmeHtml: '<h1>Hello world</h1>',
      versions: {
        __typename: 'ReleaseConnection',
        nodes: [
          {
            __typename: 'Release',
            id: 'gid://gitlab/Release/3',
            commit: {
              __typename: 'Commit',
              id: 'gid://gitlab/CommitPresenter/afa936495f20e08c26ed4a67130ee2166f94fa6e',
              pipelines: {
                __typename: 'PipelineConnection',
                nodes: [
                  {
                    __typename: 'Pipeline',
                    id: 'gid://gitlab/Ci::Pipeline/583',
                    detailedStatus: {
                      __typename: 'DetailedStatus',
                      id: 'success-583-583',
                      detailsPath: '/root/cicd-circular/-/pipelines/583',
                      icon: 'status_success',
                      text: 'passed',
                      group: 'success',
                    },
                  },
                ],
              },
            },
            tagName: 'v1.0.2',
            releasedAt: '2022-08-23T17:19:09Z',
          },
        ],
      },
    },
  },
};

const generateResourcesNodes = (count = 20, startId = 0) => {
  const nodes = [];
  for (let i = startId; i < startId + count; i += 1) {
    nodes.push({
      __typename: 'CiCatalogResource',
      id: `gid://gitlab/CiCatalogResource/${i}`,
      description: `This is a component that does a bunch of stuff and is really just a number: ${i}`,
      icon: 'my-icon',
      name: `My component #${i}`,
      starCount: 10,
      latestVersion: {
        __typename: 'Release',
        id: '3',
        tagName: '1.0.0',
        tagPath: 'path/to/release',
        releasedAt: Date.now(),
        author: { id: 1, webUrl: 'profile/1', name: 'username' },
      },
      webPath: 'path/to/project',
    });
  }

  return nodes;
};

export const mockCatalogResourceItem = generateResourcesNodes(1)[0];

export const mockComponents = {
  data: {
    ciCatalogResource: {
      __typename: 'CiCatalogResource',
      id: `gid://gitlab/CiCatalogResource/1`,
      components: {
        ...componentsMockData,
      },
    },
  },
};

export const mockComponentsEmpty = {
  data: {
    ciCatalogResource: {
      __typename: 'CiCatalogResource',
      id: `gid://gitlab/CiCatalogResource/1`,
      components: [],
    },
  },
};
