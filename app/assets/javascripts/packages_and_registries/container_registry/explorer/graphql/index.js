import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueApollo);

export const mergeVariables = (existing, incoming) => {
  if (!incoming) return existing;
  return incoming;
};

export const config = {
  cacheConfig: {
    typePolicies: {
      ContainerRepositoryDetails: {
        fields: {
          tags: {
            keyArgs: ['id', 'name', 'sort'],
            merge: mergeVariables,
          },
        },
      },
    },
  },
};

export const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient({}, config),
});
