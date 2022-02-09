export const workItemQueryResponse = {
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
          contentText: 'Test',
        },
      ],
    },
  },
};

export const updateWorkItemMutationResponse = {
  __typename: 'LocalUpdateWorkItemPayload',
  workItem: {
    __typename: 'LocalWorkItem',
    id: '1',
    widgets: {
      __typename: 'LocalWorkItemWidgetConnection',
      nodes: [
        {
          __typename: 'LocalTitleWidget',
          type: 'TITLE',
          enabled: true,
          contentText: 'Updated title',
        },
      ],
    },
  },
};

export const projectWorkItemTypesQueryResponse = {
  data: {
    workspace: {
      id: '1',
      workItemTypes: {
        nodes: [
          { id: 'work-item-1', name: 'Issue' },
          { id: 'work-item-2', name: 'Incident' },
        ],
      },
    },
  },
};
