export const workItemQueryResponse = {
  workItem: {
    __typename: 'WorkItem',
    id: '1',
    title: 'Test',
    workItemType: {
      __typename: 'WorkItemType',
      id: 'work-item-type-1',
    },
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
  data: {
    workItemUpdate: {
      __typename: 'LocalUpdateWorkItemPayload',
      workItem: {
        __typename: 'LocalWorkItem',
        id: '1',
        title: 'Updated title',
        workItemType: {
          __typename: 'WorkItemType',
          id: 'work-item-type-1',
        },
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

export const createWorkItemMutationResponse = {
  data: {
    workItemCreate: {
      __typename: 'WorkItemCreatePayload',
      workItem: {
        __typename: 'WorkItem',
        id: '1',
        title: 'Updated title',
        workItemType: {
          __typename: 'WorkItemType',
          id: 'work-item-type-1',
        },
      },
    },
  },
};
