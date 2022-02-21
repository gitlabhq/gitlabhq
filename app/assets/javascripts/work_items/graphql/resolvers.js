import { uuids } from '~/lib/utils/uuids';
import workItemQuery from './work_item.query.graphql';

export const resolvers = {
  Mutation: {
    localCreateWorkItem(_, { input }, { cache }) {
      const id = uuids()[0];
      const workItem = {
        __typename: 'LocalWorkItem',
        type: 'FEATURE',
        id,
        widgets: {
          __typename: 'LocalWorkItemWidgetConnection',
          nodes: [
            {
              __typename: 'LocalTitleWidget',
              type: 'TITLE',
              enabled: true,
              contentText: input.title,
            },
          ],
        },
      };

      cache.writeQuery({
        query: workItemQuery,
        variables: { id },
        data: { localWorkItem: workItem },
      });

      return {
        __typename: 'LocalCreateWorkItemPayload',
        workItem,
      };
    },

    localUpdateWorkItem(_, { input }, { cache }) {
      const workItemTitle = {
        __typename: 'LocalTitleWidget',
        type: 'TITLE',
        enabled: true,
        contentText: input.title,
      };
      const workItem = {
        __typename: 'LocalWorkItem',
        type: 'FEATURE',
        id: input.id,
        widgets: {
          __typename: 'LocalWorkItemWidgetConnection',
          nodes: [workItemTitle],
        },
      };

      cache.writeQuery({
        query: workItemQuery,
        variables: { id: input.id },
        data: { localWorkItem: workItem },
      });

      return {
        __typename: 'LocalUpdateWorkItemPayload',
        workItem,
      };
    },
  },
};
