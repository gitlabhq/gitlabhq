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
  });

  defaultClient.cache.writeQuery({
    query: workItemQuery,
    variables: {
      id: '1',
    },
    data: {
      workItem: {
        __typename: 'LocalWorkItem',
        id: '1',
        type: 'FEATURE',
        widgets: {
          __typename: 'LocalWorkItemWidgetConnection',
          nodes: [
            {
              __typename: 'LocalTitleWidget',
              type: 'TITLE',
              enabled: true,
              // eslint-disable-next-line @gitlab/require-i18n-strings
              contentText: 'Test Work Item Title',
            },
          ],
        },
      },
    },
  });

  return new VueApollo({
    defaultClient,
  });
}
