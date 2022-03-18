import workItemQuery from './work_item.query.graphql';

export const resolvers = {
  Mutation: {
    localUpdateWorkItem(_, { input }, { cache }) {
      const workItem = {
        __typename: 'LocalWorkItem',
        type: 'FEATURE',
        id: input.id,
        title: input.title,
        widgets: {
          __typename: 'LocalWorkItemWidgetConnection',
          nodes: [],
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
