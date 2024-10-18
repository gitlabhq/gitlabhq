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
