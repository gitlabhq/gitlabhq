import { IntrospectionFragmentMatcher } from 'apollo-cache-inmemory';
import produce from 'immer';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import introspectionQueryResultData from './graphql/fragmentTypes.json';
import getCurrentIntegrationQuery from './graphql/queries/get_current_integration.query.graphql';

const fragmentMatcher = new IntrospectionFragmentMatcher({
  introspectionQueryResultData,
});

Vue.use(VueApollo);

const resolvers = {
  Mutation: {
    updateCurrentIntegration: (
      _,
      {
        id = null,
        name,
        active,
        token,
        type,
        url,
        apiUrl,
        payloadExample,
        payloadAttributeMappings,
        payloadAlertFields,
      },
      { cache },
    ) => {
      const sourceData = cache.readQuery({ query: getCurrentIntegrationQuery });
      const data = produce(sourceData, (draftData) => {
        if (id === null) {
          draftData.currentIntegration = null;
        } else {
          draftData.currentIntegration = {
            id,
            name,
            active,
            token,
            type,
            url,
            apiUrl,
            payloadExample,
            payloadAttributeMappings,
            payloadAlertFields,
          };
        }
      });
      cache.writeQuery({ query: getCurrentIntegrationQuery, data });
    },
  },
};

export default new VueApollo({
  defaultClient: createDefaultClient(resolvers, {
    cacheConfig: {
      fragmentMatcher,
    },
    assumeImmutableResults: true,
  }),
});
