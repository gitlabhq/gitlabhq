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

export const updateWorkItemMutationResponse = {
  __typename: 'UpdateWorkItemPayload',
  workItem: {
    __typename: 'WorkItem',
    id: '1',
    widgets: {
      __typename: 'WorkItemWidgetConnection',
      nodes: [
        {
          __typename: 'TitleWidget',
          type: 'TITLE',
          enabled: true,
          contentText: 'Updated title',
        },
      ],
    },
  },
};
