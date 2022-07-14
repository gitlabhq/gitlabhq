import produce from 'immer';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { WIDGET_TYPE_ASSIGNEES, WIDGET_TYPE_WEIGHT } from '../constants';
import typeDefs from './typedefs.graphql';
import workItemQuery from './work_item.query.graphql';

export const temporaryConfig = {
  typeDefs,
  cacheConfig: {
    possibleTypes: {
      LocalWorkItemWidget: ['LocalWorkItemWeight'],
    },
    typePolicies: {
      WorkItem: {
        fields: {
          mockWidgets: {
            read(widgets) {
              return (
                widgets || [
                  {
                    __typename: 'LocalWorkItemWeight',
                    type: 'WEIGHT',
                    weight: null,
                  },
                ]
              );
            },
          },
        },
      },
    },
  },
};

export const resolvers = {
  Mutation: {
    localUpdateWorkItem(_, { input }, { cache }) {
      const sourceData = cache.readQuery({
        query: workItemQuery,
        variables: { id: input.id },
      });

      const data = produce(sourceData, (draftData) => {
        if (input.assignees) {
          const assigneesWidget = draftData.workItem.widgets.find(
            (widget) => widget.type === WIDGET_TYPE_ASSIGNEES,
          );
          assigneesWidget.assignees.nodes = [...input.assignees];
        }

        if (input.weight != null) {
          const weightWidget = draftData.workItem.mockWidgets.find(
            (widget) => widget.type === WIDGET_TYPE_WEIGHT,
          );
          weightWidget.weight = input.weight;
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

export function createApolloProvider() {
  Vue.use(VueApollo);

  const defaultClient = createDefaultClient(resolvers, temporaryConfig);

  return new VueApollo({
    defaultClient,
  });
}
