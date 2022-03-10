import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import workItemQuery from './work_item.query.graphql';
import { resolvers } from './resolvers';
import typeDefs from './typedefs.graphql';

export function createApolloProvider() {
  Vue.use(VueApollo);

  const defaultClient = createDefaultClient(resolvers, {
    typeDefs,
    cacheConfig: {
      possibleTypes: {
        LocalWorkItemWidget: ['LocalTitleWidget'],
      },
    },
  });

  defaultClient.cache.writeQuery({
    query: workItemQuery,
    variables: {
      id: 'gid://gitlab/WorkItem/1',
    },
    data: {
      localWorkItem: {
        __typename: 'LocalWorkItem',
        id: 'gid://gitlab/WorkItem/1',
        type: 'FEATURE',
        // eslint-disable-next-line @gitlab/require-i18n-strings
        title: 'Test Work Item',
        widgets: {
          __typename: 'LocalWorkItemWidgetConnection',
          nodes: [],
        },
      },
    },
  });

  return new VueApollo({
    defaultClient,
  });
}
