import produce from 'immer';
import VueApollo from 'vue-apollo';
import { concatPagination } from '@apollo/client/utilities';
import getIssueStateQuery from '~/issues/show/queries/get_issue_state.query.graphql';
import createDefaultClient from '~/lib/graphql';
import typeDefs from '~/work_items/graphql/typedefs.graphql';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import { WIDGET_TYPE_LABELS } from '~/work_items/constants';

export const temporaryConfig = {
  typeDefs,
  cacheConfig: {
    possibleTypes: {
      LocalWorkItemWidget: ['LocalWorkItemLabels'],
    },
    typePolicies: {
      Project: {
        fields: {
          projectMembers: {
            keyArgs: ['fullPath', 'search', 'relations', 'first'],
          },
        },
      },
      WorkItem: {
        fields: {
          mockWidgets: {
            read(widgets) {
              return (
                widgets || [
                  {
                    __typename: 'LocalWorkItemLabels',
                    type: WIDGET_TYPE_LABELS,
                    allowScopedLabels: true,
                    nodes: [],
                  },
                ]
              );
            },
          },
          widgets: {
            merge(_, incoming) {
              return incoming;
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
    localUpdateWorkItem(_, { input }, { cache }) {
      const sourceData = cache.readQuery({
        query: workItemQuery,
        variables: { id: input.id },
      });

      const data = produce(sourceData, (draftData) => {
        if (input.labels) {
          const labelsWidget = draftData.workItem.mockWidgets.find(
            (widget) => widget.type === WIDGET_TYPE_LABELS,
          );
          labelsWidget.nodes = [...input.labels];
        }
      });

      cache.writeQuery({
        query: workItemQuery,
        variables: { id: input.id },
        data,
      });
    },
  },
};

export const defaultClient = createDefaultClient(resolvers, temporaryConfig);

export const apolloProvider = new VueApollo({
  defaultClient,
});
