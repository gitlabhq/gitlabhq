const componentsDetailsMockData = {
  __typename: 'CiComponentConnection',
  nodes: [
    {
      id: 'gid://gitlab/Ci::Component/1',
      name: 'Ruby gal',
      description: 'This is a pretty amazing component that does EVERYTHING ruby.',
      includePath: 'gitlab.com/gitlab-org/ruby-gal@~latest',
      inputs: [
        {
          name: 'version',
          default: '1.0.0',
          description: 'here is a test description',
          required: true,
          type: 'STRING',
        },
      ],
    },
    {
      id: 'gid://gitlab/Ci::Component/2',
      name: 'Javascript madness',
      description: 'Adds some spice to your life.',
      includePath: 'gitlab.com/gitlab-org/javascript-madness@~latest',
      inputs: [
        {
          name: 'isFun',
          default: 'true',
          description: 'this is a boolean',
          required: true,
          type: 'BOOLEAN',
        },
        {
          name: 'RandomNumber',
          default: '10',
          description: 'a number',
          required: false,
          type: 'NUMBER',
        },
        {
          name: 'RandomNumber',
          default: '10',
          description: 'another number',
          required: false,
          type: 'NUMBER',
        },
      ],
    },
    {
      id: 'gid://gitlab/Ci::Component/3',
      name: 'Go go go',
      description: 'When you write Go, you gotta go go go.',
      includePath: 'gitlab.com/gitlab-org/go-go-go@~latest',
      inputs: [
        {
          name: 'version',
          default: '1.0.0',
          description: 'a version',
          required: true,
          type: 'STRING',
        },
      ],
    },
  ],
};

const componentsListMockData = {
  nodes: [
    {
      id: 'gid://gitlab/Ci::Catalog::Resources::Component/2',
      name: 'test-component',
      __typename: 'CiCatalogResourceComponent',
    },
    {
      id: 'gid://gitlab/Ci::Catalog::Resources::Component/1',
      name: 'component_two',
      __typename: 'CiCatalogResourceComponent',
    },
  ],
  __typename: 'CiCatalogResourceComponentConnection',
};

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
      nodes: [],
    },
  },
};

export const catalogResourcesCountResponseBody = {
  data: {
    ciCatalogResources: {
      all: {
        count: 1,
        __typename: 'CiCatalogResourceConnection',
      },
      namespaces: {
        count: 7,
        __typename: 'CiCatalogResourceConnection',
      },
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
      nodes: [
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/129',
          icon: null,
          name: 'Project-42 Name',
          description: 'A simple component',
          starCount: 0,
          last30DayUsageCount: 0,
          starrersPath: '/frontend-fixtures/project-42/-/starrers',
          topics: [],
          verificationLevel: 'UNVERIFIED',
          versions: {
            nodes: [],
            __typename: 'CiCatalogResourceVersionConnection',
          },
          visibilityLevel: 'public',
          webPath: '/frontend-fixtures/project-42',
          fullPath: 'namespace/frontend-fixtures/project-42',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/128',
          icon: null,
          name: 'Project-41 Name',
          description: 'A simple component',
          starCount: 0,
          last30DayUsageCount: 0,
          starrersPath: '/frontend-fixtures/project-41/-/starrers',
          topics: [],
          verificationLevel: 'UNVERIFIED',
          versions: {
            nodes: [],
            __typename: 'CiCatalogResourceVersionConnection',
          },
          visibilityLevel: 'public',
          webPath: '/frontend-fixtures/project-41',
          fullPath: 'namespace/frontend-fixtures/project-41',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/127',
          icon: null,
          name: 'Project-40 Name',
          description: 'A simple component',
          starCount: 0,
          last30DayUsageCount: 0,
          starrersPath: '/frontend-fixtures/project-40/-/starrers',
          topics: [],
          verificationLevel: 'UNVERIFIED',
          versions: {
            nodes: [],
            __typename: 'CiCatalogResourceVersionConnection',
          },
          visibilityLevel: 'public',
          webPath: '/frontend-fixtures/project-42',
          fullPath: 'namespace/frontend-fixtures/project-42',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/126',
          icon: null,
          name: 'Project-39 Name',
          description: 'A simple component',
          starCount: 0,
          last30DayUsageCount: 0,
          starrersPath: '/frontend-fixtures/project-39/-/starrers',
          topics: [],
          verificationLevel: 'UNVERIFIED',
          versions: {
            nodes: [],
            __typename: 'CiCatalogResourceVersionConnection',
          },
          visibilityLevel: 'public',
          webPath: '/frontend-fixtures/project-39',
          fullPath: 'namespace/frontend-fixtures/project-39',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/125',
          icon: null,
          name: 'Project-38 Name',
          description: 'A simple component',
          starCount: 0,
          last30DayUsageCount: 0,
          starrersPath: '/frontend-fixtures/project-38/-/starrers',
          topics: [],
          verificationLevel: 'UNVERIFIED',
          versions: {
            nodes: [],
            __typename: 'CiCatalogResourceVersionConnection',
          },
          visibilityLevel: 'public',
          webPath: '/frontend-fixtures/project-38',
          fullPath: 'namespace/frontend-fixtures/project-38',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/124',
          icon: null,
          name: 'Project-37 Name',
          description: 'A simple component',
          starCount: 0,
          last30DayUsageCount: 0,
          starrersPath: '/frontend-fixtures/project-37/-/starrers',
          topics: [],
          verificationLevel: 'UNVERIFIED',
          versions: {
            nodes: [],
            __typename: 'CiCatalogResourceVersionConnection',
          },
          visibilityLevel: 'public',
          webPath: '/frontend-fixtures/project-37',
          fullPath: 'namespace/frontend-fixtures/project-37',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/123',
          icon: null,
          name: 'Project-36 Name',
          description: 'A simple component',
          starCount: 0,
          last30DayUsageCount: 0,
          starrersPath: '/frontend-fixtures/project-36/-/starrers',
          topics: [],
          verificationLevel: 'UNVERIFIED',
          versions: {
            nodes: [],
            __typename: 'CiCatalogResourceVersionConnection',
          },
          visibilityLevel: 'public',
          webPath: '/frontend-fixtures/project-36',
          fullPath: 'namespace/frontend-fixtures/project-36',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/122',
          icon: null,
          name: 'Project-35 Name',
          description: 'A simple component',
          starCount: 0,
          last30DayUsageCount: 0,
          starrersPath: '/frontend-fixtures/project-35/-/starrers',
          topics: [],
          verificationLevel: 'UNVERIFIED',
          versions: {
            nodes: [],
            __typename: 'CiCatalogResourceVersionConnection',
          },
          visibilityLevel: 'public',
          webPath: '/frontend-fixtures/project-35',
          fullPath: 'namespace/frontend-fixtures/project-35',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/121',
          icon: null,
          name: 'Project-34 Name',
          description: 'A simple component',
          starCount: 0,
          last30DayUsageCount: 0,
          starrersPath: '/frontend-fixtures/project-34/-/starrers',
          topics: [],
          verificationLevel: 'UNVERIFIED',
          versions: {
            nodes: [],
            __typename: 'CiCatalogResourceVersionConnection',
          },
          visibilityLevel: 'public',
          webPath: '/frontend-fixtures/project-34',
          fullPath: 'namespace/frontend-fixtures/project-34',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/120',
          icon: null,
          name: 'Project-33 Name',
          description: 'A simple component',
          starCount: 0,
          last30DayUsageCount: 0,
          starrersPath: '/frontend-fixtures/project-33/-/starrers',
          topics: [],
          verificationLevel: 'UNVERIFIED',
          versions: {
            nodes: [],
            __typename: 'CiCatalogResourceVersionConnection',
          },
          visibilityLevel: 'public',
          webPath: '/frontend-fixtures/project-33',
          fullPath: 'namespace/frontend-fixtures/project-33',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/119',
          icon: null,
          name: 'Project-32 Name',
          description: 'A simple component',
          starCount: 0,
          last30DayUsageCount: 0,
          starrersPath: '/frontend-fixtures/project-32/-/starrers',
          topics: [],
          verificationLevel: 'UNVERIFIED',
          versions: {
            nodes: [],
            __typename: 'CiCatalogResourceVersionConnection',
          },
          visibilityLevel: 'public',
          webPath: '/frontend-fixtures/project-32',
          fullPath: 'namespace/frontend-fixtures/project-32',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/118',
          icon: null,
          name: 'Project-31 Name',
          description: 'A simple component',
          starCount: 0,
          last30DayUsageCount: 0,
          starrersPath: '/frontend-fixtures/project-31/-/starrers',
          topics: [],
          verificationLevel: 'UNVERIFIED',
          versions: {
            nodes: [],
            __typename: 'CiCatalogResourceVersionConnection',
          },
          visibilityLevel: 'public',
          webPath: '/frontend-fixtures/project-31',
          fullPath: 'namespace/frontend-fixtures/project-31',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/117',
          icon: null,
          name: 'Project-30 Name',
          description: 'A simple component',
          starCount: 0,
          last30DayUsageCount: 0,
          starrersPath: '/frontend-fixtures/project-30/-/starrers',
          topics: [],
          verificationLevel: 'UNVERIFIED',
          versions: {
            nodes: [],
            __typename: 'CiCatalogResourceVersionConnection',
          },
          visibilityLevel: 'public',
          webPath: '/frontend-fixtures/project-30',
          fullPath: 'namespace/frontend-fixtures/project-30',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/116',
          icon: null,
          name: 'Project-29 Name',
          description: 'A simple component',
          starCount: 0,
          last30DayUsageCount: 0,
          starrersPath: '/frontend-fixtures/project-29/-/starrers',
          topics: [],
          verificationLevel: 'UNVERIFIED',
          versions: {
            nodes: [],
            __typename: 'CiCatalogResourceVersionConnection',
          },
          visibilityLevel: 'public',
          webPath: '/frontend-fixtures/project-29',
          fullPath: 'namespace/frontend-fixtures/project-29',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/115',
          icon: null,
          name: 'Project-28 Name',
          description: 'A simple component',
          starCount: 0,
          last30DayUsageCount: 0,
          starrersPath: '/frontend-fixtures/project-28/-/starrers',
          topics: [],
          verificationLevel: 'UNVERIFIED',
          versions: {
            nodes: [],
            __typename: 'CiCatalogResourceVersionConnection',
          },
          visibilityLevel: 'public',
          webPath: '/frontend-fixtures/project-28',
          fullPath: 'namespace/frontend-fixtures/project-28',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/114',
          icon: null,
          name: 'Project-27 Name',
          description: 'A simple component',
          starCount: 0,
          last30DayUsageCount: 0,
          starrersPath: '/frontend-fixtures/project-27/-/starrers',
          topics: [],
          verificationLevel: 'UNVERIFIED',
          versions: {
            nodes: [],
            __typename: 'CiCatalogResourceVersionConnection',
          },
          visibilityLevel: 'public',
          webPath: '/frontend-fixtures/project-27',
          fullPath: 'namespace/frontend-fixtures/project-27',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/113',
          icon: null,
          name: 'Project-26 Name',
          description: 'A simple component',
          starCount: 0,
          last30DayUsageCount: 0,
          starrersPath: '/frontend-fixtures/project-26/-/starrers',
          topics: [],
          verificationLevel: 'UNVERIFIED',
          versions: {
            nodes: [],
            __typename: 'CiCatalogResourceVersionConnection',
          },
          visibilityLevel: 'public',
          webPath: '/frontend-fixtures/project-26',
          fullPath: 'namespace/frontend-fixtures/project-26',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/112',
          icon: null,
          name: 'Project-25 Name',
          description: 'A simple component',
          starCount: 0,
          last30DayUsageCount: 0,
          starrersPath: '/frontend-fixtures/project-25/-/starrers',
          topics: [],
          verificationLevel: 'UNVERIFIED',
          versions: {
            nodes: [],
            __typename: 'CiCatalogResourceVersionConnection',
          },
          visibilityLevel: 'public',
          webPath: '/frontend-fixtures/project-25',
          fullPath: 'namespace/frontend-fixtures/project-25',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/111',
          icon: null,
          name: 'Project-24 Name',
          description: 'A simple component',
          starCount: 0,
          last30DayUsageCount: 0,
          starrersPath: '/frontend-fixtures/project-24/-/starrers',
          topics: [],
          verificationLevel: 'UNVERIFIED',
          versions: {
            nodes: [],
            __typename: 'CiCatalogResourceVersionConnection',
          },
          visibilityLevel: 'public',
          webPath: '/frontend-fixtures/project-24',
          fullPath: 'namespace/frontend-fixtures/project-24',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/110',
          icon: null,
          name: 'Project-23 Name',
          description: 'A simple component',
          starCount: 0,
          last30DayUsageCount: 0,
          starrersPath: '/frontend-fixtures/project-23/-/starrers',
          topics: [],
          verificationLevel: 'UNVERIFIED',
          versions: {
            nodes: [],
            __typename: 'CiCatalogResourceVersionConnection',
          },
          visibilityLevel: 'public',
          webPath: '/frontend-fixtures/project-23',
          fullPath: 'namespace/frontend-fixtures/project-23',
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
      nodes: [
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/132',
          icon: null,
          name: 'Project-45 Name',
          description: 'A simple component',
          starCount: 0,
          last30DayUsageCount: 4,
          verificationLevel: 'UNVERIFIED',
          versions: {
            __typename: 'CiCatalogResourceVersionConnection',
            nodes: [
              {
                id: 'gid://gitlab/Ci::Catalog::Resources::Version/2',
                author: {
                  __typename: 'UserCore',
                  name: 'author',
                  username: 'author-username',
                  webUrl: '/user/1',
                },
                createdAt: '2024-01-26T19:40:03Z',
                name: '1.0.0',
                path: '/root/catalog-component-test/-/tags/1.0.2',
                components: {
                  ...componentsListMockData,
                },
                __typename: 'CiCatalogResourceVersion',
              },
            ],
          },
          visibilityLevel: 'public',
          webPath: '/frontend-fixtures/project-45',
          fullPath: 'namespace/frontend-fixtures/project-45',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/131',
          icon: null,
          name: 'Project-44 Name',
          description: 'A simple component',
          starCount: 0,
          verificationLevel: 'UNVERIFIED',
          versions: {
            nodes: [],
            __typename: 'CiCatalogResourceVersionConnection',
          },
          visibilityLevel: 'private',
          webPath: '/frontend-fixtures/project-44',
          fullPath: 'namespace/frontend-fixtures/project-44',
          __typename: 'CiCatalogResource',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resource/130',
          icon: null,
          name: 'Project-43 Name',
          description: 'A simple component',
          starCount: 0,
          verificationLevel: 'UNVERIFIED',
          versions: {
            nodes: [],
            __typename: 'CiCatalogResourceVersionConnection',
          },
          visibilityLevel: 'public',
          webPath: '/frontend-fixtures/project-43',
          fullPath: 'namespace/frontend-fixtures/project-43',
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
      last30DayUsageCount: 4,
      starrersPath: '/path/to/project/-/starrers',
      topics: [],
      verificationLevel: 'UNVERIFIED',
      versions: {
        __typename: 'CiCatalogResourceVersionConnection',
        nodes: [
          {
            __typename: 'CiCatalogResourceVersion',
            id: '3',
            components: componentsListMockData,
            name: '1.0.0',
            path: 'path/to/release',
            createdAt: Date.now(),
            author: {
              __typename: 'UserCore',
              id: 1,
              webUrl: 'profile/1',
              name: 'username',
              state: 'active',
            },
          },
        ],
      },
      visibilityLevel: 'public',
      webPath: '/path/to/project',
      fullPath: 'namespace/path/to/project',
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
      last30DayUsageCount: 4,
      versions: {
        __typename: 'CiCatalogResourceVersionConnection',
        nodes: [
          {
            __typename: 'CiCatalogResourceVersion',
            id: '3',
            components: {
              ...componentsListMockData,
            },
            name: '1.0.0',
            path: 'path/to/release',
            createdAt: Date.now(),
            author: {
              __typename: 'UserCore',
              id: 1,
              webUrl: 'profile/1',
              name: 'username',
            },
          },
        ],
      },
      webPath: 'path/to/project',
      fullPath: 'namespace/path/to/project',
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
      webPath: '/twitter/project-1',
      versions: {
        __typename: 'CiCatalogResourceVersionConnection',
        nodes: [
          {
            id: 'gid://gitlab/Version/1',
            components: {
              ...componentsDetailsMockData,
            },
          },
        ],
      },
    },
  },
};

export const mockComponentsEmpty = {
  data: {
    ciCatalogResource: {
      __typename: 'CiCatalogResource',
      id: `gid://gitlab/CiCatalogResource/1`,
      webPath: '/twitter/project-1',
      versions: {
        __typename: 'CiCatalogResourceVersionConnection',
        nodes: [
          {
            id: 'gid://gitlab/Version/1',
            components: [],
          },
        ],
      },
    },
  },
};

export const longResourceDescription =
  'This innovative project leverages cutting-edge microservices architecture to deliver scalable cloud-native solutions. With comprehensive CI/CD pipelines, automated testing frameworks, and robust monitoring capabilities, it ensures reliable deployments and optimal performance. The modular design incorporates industry best practices for security, maintainability and extensibility. Advanced caching mechanisms and efficient database optimization techniques provide lightning-fast response times. Built using modern development frameworks and tools, it seamlessly integrates with existing enterprise systems while maintaining flexibility for future enhancements.';
