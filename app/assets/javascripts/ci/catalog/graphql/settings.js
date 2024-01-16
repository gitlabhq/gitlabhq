import getCurrentPage from './queries/client/get_current_page.query.graphql';

export const ciCatalogResourcesItemsCount = 20;
export const CI_CATALOG_RESOURCE_TYPE = 'Ci::Catalog::Resource';

export const cacheConfig = {
  typePolicies: {
    Query: {
      fields: {
        ciCatalogResource(_, { args, toReference }) {
          return toReference({
            __typename: 'CiCatalogResource',
            // Webpath is the fullpath with a leading slash
            webPath: `/${args.fullPath}`,
          });
        },
        ciCatalogResources: {
          keyArgs: ['scope', 'search', 'sort'],
        },
      },
    },
    CiCatalogResource: {
      keyFields: ['webPath'],
    },
  },
};

export const resolvers = {
  Mutation: {
    updateCurrentPage: (_, { pageNumber }, { cache }) => {
      cache.writeQuery({
        query: getCurrentPage,
        data: {
          page: {
            __typename: 'CatalogPage',
            current: pageNumber,
          },
        },
      });
    },
  },
};
