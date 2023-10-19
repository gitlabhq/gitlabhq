import { componentsMockData } from '../constants';

export const ciCatalogResourcesItemsCount = 20;
export const CI_CATALOG_RESOURCE_TYPE = 'Ci::Catalog::Resource';

export const cacheConfig = {
  cacheConfig: {
    typePolicies: {
      Query: {
        fields: {
          ciCatalogResource(_, { args, toReference }) {
            return toReference({
              __typename: 'CiCatalogResource',
              id: args.id,
            });
          },
          ciCatalogResources: {
            keyArgs: false,
          },
        },
      },
    },
  },
};

export const resolvers = {
  CiCatalogResource: {
    components() {
      return componentsMockData;
    },
  },
};
