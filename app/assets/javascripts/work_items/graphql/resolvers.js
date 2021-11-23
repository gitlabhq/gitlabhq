import { uuids } from '~/lib/utils/uuids';
import workItemQuery from './work_item.query.graphql';

export const resolvers = {
  Mutation: {
    createWorkItem(_, { input }, { cache }) {
      const id = uuids()[0];
      const workItem = {
        __typename: 'WorkItem',
        type: 'FEATURE',
        id,
        widgets: {
          __typename: 'WorkItemWidgetConnection',
          nodes: [
            {
              __typename: 'TitleWidget',
              type: 'TITLE',
              enabled: true,
              contentText: input.title,
            },
          ],
        },
      };

      cache.writeQuery({ query: workItemQuery, variables: { id }, data: { workItem } });

      return {
        __typename: 'CreateWorkItemPayload',
        workItem,
      };
    },
  },
};
