import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueApollo);

export const mergeVariables = (existing, incoming) => {
  if (!incoming) return existing;
  return incoming;
};

export const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(
    {},
    {
      cacheConfig: {
        typePolicies: {
          PackageDetailsType: {
            fields: {
              versions: {
                keyArgs: false,
                merge: mergeVariables,
              },
              packageFiles: {
                keyArgs: ['id'],
                merge: mergeVariables,
              },
            },
          },
        },
      },
    },
  ),
});
