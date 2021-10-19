export const workItemQueryResponse = {
  workItem: {
    __typename: 'WorkItem',
    id: '1',
    type: 'FEATURE',
    widgets: {
      __typename: 'WorkItemWidgetConnection',
      nodes: [
        {
          __typename: 'TitleWidget',
          type: 'TITLE',
          contentText: 'Test',
        },
      ],
    },
  },
};
