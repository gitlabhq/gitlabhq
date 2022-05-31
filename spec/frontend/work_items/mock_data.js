export const workItemQueryResponse = {
  data: {
    workItem: {
      __typename: 'WorkItem',
      id: 'gid://gitlab/WorkItem/1',
      title: 'Test',
      state: 'OPEN',
      description: 'description',
      workItemType: {
        __typename: 'WorkItemType',
        id: 'gid://gitlab/WorkItems::Type/5',
        name: 'Task',
      },
      userPermissions: {
        deleteWorkItem: false,
        updateWorkItem: false,
      },
      widgets: [
        {
          __typename: 'WorkItemWidgetDescription',
          type: 'DESCRIPTION',
          description: 'some **great** text',
          descriptionHtml:
            '<p data-sourcepos="1:1-1:19" dir="auto">some <strong>great</strong> text</p>',
        },
      ],
    },
  },
};

export const updateWorkItemMutationResponse = {
  data: {
    workItemUpdate: {
      __typename: 'WorkItemUpdatePayload',
      workItem: {
        __typename: 'WorkItem',
        id: 'gid://gitlab/WorkItem/1',
        title: 'Updated title',
        state: 'OPEN',
        description: 'description',
        workItemType: {
          __typename: 'WorkItemType',
          id: 'gid://gitlab/WorkItems::Type/5',
          name: 'Task',
        },
        userPermissions: {
          deleteWorkItem: false,
          updateWorkItem: false,
        },
        widgets: [],
      },
    },
  },
};

export const projectWorkItemTypesQueryResponse = {
  data: {
    workspace: {
      id: 'gid://gitlab/WorkItem/1',
      workItemTypes: {
        nodes: [
          { id: 'gid://gitlab/WorkItems::Type/1', name: 'Issue' },
          { id: 'gid://gitlab/WorkItems::Type/2', name: 'Incident' },
          { id: 'gid://gitlab/WorkItems::Type/3', name: 'Task' },
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
        id: 'gid://gitlab/WorkItem/1',
        title: 'Updated title',
        state: 'OPEN',
        description: 'description',
        workItemType: {
          __typename: 'WorkItemType',
          id: 'gid://gitlab/WorkItems::Type/5',
          name: 'Task',
        },
        userPermissions: {
          deleteWorkItem: false,
          updateWorkItem: false,
        },
        widgets: [],
      },
    },
  },
};

export const createWorkItemFromTaskMutationResponse = {
  data: {
    workItemCreateFromTask: {
      __typename: 'WorkItemCreateFromTaskPayload',
      errors: [],
      workItem: {
        descriptionHtml: '<p>New description</p>',
        id: 'gid://gitlab/WorkItem/13',
        __typename: 'WorkItem',
        userPermissions: {
          deleteWorkItem: false,
          updateWorkItem: false,
        },
      },
    },
  },
};

export const deleteWorkItemResponse = {
  data: { workItemDelete: { errors: [], __typename: 'WorkItemDeletePayload' } },
};

export const deleteWorkItemFailureResponse = {
  data: { workItemDelete: null },
  errors: [
    {
      message:
        "The resource that you are attempting to access does not exist or you don't have permission to perform this action",
      locations: [{ line: 2, column: 3 }],
      path: ['workItemDelete'],
    },
  ],
};

export const workItemTitleSubscriptionResponse = {
  data: {
    issuableTitleUpdated: {
      id: 'gid://gitlab/WorkItem/1',
      title: 'new title',
    },
  },
};
