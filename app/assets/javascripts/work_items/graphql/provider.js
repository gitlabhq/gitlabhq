import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import typeDefs from './typedefs.graphql';

export const temporaryConfig = {
  typeDefs,
  cacheConfig: {
    possibleTypes: {
      LocalWorkItemWidget: ['LocalWorkItemAssignees'],
    },
    typePolicies: {
      WorkItem: {
        fields: {
          mockWidgets: {
            read() {
              return [
                {
                  __typename: 'LocalWorkItemAssignees',
                  type: 'ASSIGNEES',
                  nodes: [
                    {
                      __typename: 'UserCore',
                      id: 'gid://gitlab/User/1',
                      avatarUrl: '',
                      webUrl: '',
                      // eslint-disable-next-line @gitlab/require-i18n-strings
                      name: 'John Doe',
                      username: 'doe_I',
                    },
                    {
                      __typename: 'UserCore',
                      id: 'gid://gitlab/User/2',
                      avatarUrl: '',
                      webUrl: '',
                      // eslint-disable-next-line @gitlab/require-i18n-strings
                      name: 'Marcus Rutherford',
                      username: 'ruthfull',
                    },
                  ],
                },
              ];
            },
          },
        },
      },
    },
  },
};

export function createApolloProvider() {
  Vue.use(VueApollo);

  const defaultClient = createDefaultClient({}, temporaryConfig);

  return new VueApollo({
    defaultClient,
  });
}
