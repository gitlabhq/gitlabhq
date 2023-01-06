import produce from 'immer';
import VueApollo from 'vue-apollo';
import { defaultDataIdFromObject } from '@apollo/client/core';
import { concatPagination } from '@apollo/client/utilities';
import getIssueStateQuery from '~/issues/show/queries/get_issue_state.query.graphql';
import createDefaultClient from '~/lib/graphql';
import typeDefs from '~/work_items/graphql/typedefs.graphql';
import { WIDGET_TYPE_NOTES } from '~/work_items/constants';

export const config = {
  typeDefs,
  cacheConfig: {
    // included temporarily until Vuex is removed from boards app
    dataIdFromObject: (object) => {
      // eslint-disable-next-line no-underscore-dangle
      return object.__typename === 'BoardList' ? object.iid : defaultDataIdFromObject(object);
    },
    typePolicies: {
      Project: {
        fields: {
          projectMembers: {
            keyArgs: ['fullPath', 'search', 'relations', 'first'],
          },
        },
      },
      WorkItemWidgetNotes: {
        fields: {
          // If we add any key args, the discussions field becomes discussions({"filter":"ONLY_ACTIVITY","first":10}) and
          // kills any possibility to handle it on the widget level without hardcoding a string.
          discussions: {
            keyArgs: false,
          },
        },
      },
      WorkItem: {
        fields: {
          // widgets policy because otherwise the subscriptions invalidate the cache
          widgets: {
            merge(existing = [], incoming, context) {
              if (existing.length === 0) {
                return incoming;
              }
              return existing.map((existingWidget) => {
                const incomingWidget = incoming.find(
                  (w) => w.type && w.type === existingWidget.type,
                );
                // We don't want to override existing notes with empty widget on work item updates
                if (incomingWidget?.type === WIDGET_TYPE_NOTES && !context.variables.pageSize) {
                  return existingWidget;
                }
                // we want to concat next page of discussions to the existing ones
                if (incomingWidget?.type === WIDGET_TYPE_NOTES && context.variables.after) {
                  // concatPagination won't work because we were placing new widget here so we have to do this manually
                  return {
                    ...incomingWidget,
                    discussions: {
                      ...incomingWidget.discussions,
                      nodes: [
                        ...existingWidget.discussions.nodes,
                        ...incomingWidget.discussions.nodes,
                      ],
                    },
                  };
                }
                return incomingWidget || existingWidget;
              });
            },
          },
        },
      },
      MemberInterfaceConnection: {
        fields: {
          nodes: concatPagination(),
        },
      },
    },
  },
};

export const resolvers = {
  Mutation: {
    updateIssueState: (_, { issueType = undefined, isDirty = false }, { cache }) => {
      const sourceData = cache.readQuery({ query: getIssueStateQuery });
      const data = produce(sourceData, (draftData) => {
        draftData.issueState = { issueType, isDirty };
      });
      cache.writeQuery({ query: getIssueStateQuery, data });
    },
  },
};

export const defaultClient = createDefaultClient(resolvers, config);

export const apolloProvider = new VueApollo({
  defaultClient,
});
