export const mockAssignees = [
  {
    __typename: 'UserCore',
    id: 'gid://gitlab/User/1',
    avatarUrl: '',
    webUrl: '',
    name: 'John Doe',
    username: 'doe_I',
  },
  {
    __typename: 'UserCore',
    id: 'gid://gitlab/User/2',
    avatarUrl: '',
    webUrl: '',
    name: 'Marcus Rutherford',
    username: 'ruthfull',
  },
];

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
        {
          __typename: 'WorkItemWidgetAssignees',
          type: 'ASSIGNEES',
          allowsMultipleAssignees: true,
          assignees: {
            nodes: mockAssignees,
          },
        },
        {
          __typename: 'WorkItemWidgetHierarchy',
          type: 'HIERARCHY',
          parent: {
            id: 'gid://gitlab/Issue/1',
            iid: '5',
            title: 'Parent title',
          },
          children: {
            nodes: [
              {
                id: 'gid://gitlab/WorkItem/444',
              },
            ],
          },
        },
      ],
    },
  },
};

export const updateWorkItemMutationResponse = {
  data: {
    workItemUpdate: {
      __typename: 'WorkItemUpdatePayload',
      errors: [],
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
        widgets: [
          {
            children: {
              nodes: [
                {
                  id: 'gid://gitlab/WorkItem/444',
                },
              ],
            },
          },
        ],
      },
    },
  },
};

export const workItemResponseFactory = ({
  canUpdate = false,
  allowsMultipleAssignees = true,
  assigneesWidgetPresent = true,
  weightWidgetPresent = true,
  parent = null,
} = {}) => ({
  data: {
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
        updateWorkItem: canUpdate,
      },
      widgets: [
        {
          __typename: 'WorkItemWidgetDescription',
          type: 'DESCRIPTION',
          description: 'some **great** text',
          descriptionHtml:
            '<p data-sourcepos="1:1-1:19" dir="auto">some <strong>great</strong> text</p>',
        },
        assigneesWidgetPresent
          ? {
              __typename: 'WorkItemWidgetAssignees',
              type: 'ASSIGNEES',
              allowsMultipleAssignees,
              assignees: {
                nodes: mockAssignees,
              },
            }
          : { type: 'MOCK TYPE' },
        weightWidgetPresent
          ? {
              __typename: 'WorkItemWidgetWeight',
              type: 'WEIGHT',
              weight: 0,
            }
          : { type: 'MOCK TYPE' },
        {
          __typename: 'WorkItemWidgetHierarchy',
          type: 'HIERARCHY',
          children: {
            nodes: [
              {
                id: 'gid://gitlab/WorkItem/444',
              },
            ],
          },
          parent,
        },
      ],
    },
  },
});

export const updateWorkItemWidgetsResponse = {
  data: {
    workItemUpdateWidgets: {
      workItem: {
        id: 1234,
      },
      errors: [],
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
        __typename: 'WorkItem',
        description: 'New description',
        id: 'gid://gitlab/WorkItem/1',
        title: 'Updated title',
        state: 'OPEN',
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
            description: 'New description',
            descriptionHtml: '<p>New description</p>',
          },
        ],
      },
      newWorkItem: {
        __typename: 'WorkItem',
        id: 'gid://gitlab/WorkItem/1000000',
        title: 'Updated title',
        state: 'OPEN',
        description: '',
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

export const workItemHierarchyEmptyResponse = {
  data: {
    workItem: {
      id: 'gid://gitlab/WorkItem/1',
      workItemType: {
        id: 'gid://gitlab/WorkItems::Type/6',
        __typename: 'WorkItemType',
      },
      title: 'New title',
      widgets: [
        {
          type: 'DESCRIPTION',
          __typename: 'WorkItemWidgetDescription',
        },
        {
          type: 'HIERARCHY',
          parent: null,
          children: {
            nodes: [],
            __typename: 'WorkItemConnection',
          },
          __typename: 'WorkItemWidgetHierarchy',
        },
      ],
      __typename: 'WorkItem',
    },
  },
};

export const workItemHierarchyResponse = {
  data: {
    workItem: {
      id: 'gid://gitlab/WorkItem/1',
      workItemType: {
        id: 'gid://gitlab/WorkItems::Type/6',
        __typename: 'WorkItemType',
      },
      title: 'New title',
      widgets: [
        {
          type: 'DESCRIPTION',
          __typename: 'WorkItemWidgetDescription',
        },
        {
          type: 'HIERARCHY',
          parent: null,
          children: {
            nodes: [
              {
                id: 'gid://gitlab/WorkItem/2',
                workItemType: {
                  id: 'gid://gitlab/WorkItems::Type/5',
                  __typename: 'WorkItemType',
                },
                title: 'xyz',
                state: 'OPEN',
                __typename: 'WorkItem',
              },
              {
                id: 'gid://gitlab/WorkItem/3',
                workItemType: {
                  id: 'gid://gitlab/WorkItems::Type/5',
                  __typename: 'WorkItemType',
                },
                title: 'abc',
                state: 'CLOSED',
                __typename: 'WorkItem',
              },
              {
                id: 'gid://gitlab/WorkItem/4',
                workItemType: {
                  id: 'gid://gitlab/WorkItems::Type/5',
                  __typename: 'WorkItemType',
                },
                title: 'bar',
                state: 'OPEN',
                __typename: 'WorkItem',
              },
              {
                id: 'gid://gitlab/WorkItem/5',
                workItemType: {
                  id: 'gid://gitlab/WorkItems::Type/5',
                  __typename: 'WorkItemType',
                },
                title: 'foobar',
                state: 'OPEN',
                __typename: 'WorkItem',
              },
            ],
            __typename: 'WorkItemConnection',
          },
          __typename: 'WorkItemWidgetHierarchy',
        },
      ],
      __typename: 'WorkItem',
    },
  },
};

export const changeWorkItemParentMutationResponse = {
  data: {
    workItemUpdate: {
      workItem: {
        id: 'gid://gitlab/WorkItem/2',
        workItemType: {
          id: 'gid://gitlab/WorkItems::Type/5',
          __typename: 'WorkItemType',
        },
        title: 'Foo',
        state: 'OPEN',
        __typename: 'WorkItem',
      },
      errors: [],
      __typename: 'WorkItemUpdatePayload',
    },
  },
};

export const availableWorkItemsResponse = {
  data: {
    workspace: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/2',
      workItems: {
        edges: [
          {
            node: {
              id: 'gid://gitlab/WorkItem/458',
              title: 'Task 1',
              state: 'OPEN',
            },
          },
          {
            node: {
              id: 'gid://gitlab/WorkItem/459',
              title: 'Task 2',
              state: 'OPEN',
            },
          },
        ],
      },
    },
  },
};

export const projectMembersResponseWithCurrentUser = {
  data: {
    workspace: {
      id: '1',
      __typename: 'Project',
      users: {
        nodes: [
          {
            id: 'user-2',
            user: {
              __typename: 'UserCore',
              id: 'gid://gitlab/User/5',
              avatarUrl: '/avatar2',
              name: 'rookie',
              username: 'rookie',
              webUrl: 'rookie',
              status: null,
            },
          },
          {
            id: 'user-1',
            user: {
              __typename: 'UserCore',
              id: 'gid://gitlab/User/1',
              avatarUrl:
                'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
              name: 'Administrator',
              username: 'root',
              webUrl: '/root',
              status: null,
            },
          },
        ],
      },
    },
  },
};

export const projectMembersResponseWithoutCurrentUser = {
  data: {
    workspace: {
      id: '1',
      __typename: 'Project',
      users: {
        nodes: [
          {
            id: 'user-2',
            user: {
              __typename: 'UserCore',
              id: 'gid://gitlab/User/5',
              avatarUrl: '/avatar2',
              name: 'rookie',
              username: 'rookie',
              webUrl: 'rookie',
              status: null,
            },
          },
        ],
      },
    },
  },
};

export const currentUserResponse = {
  data: {
    currentUser: {
      __typename: 'UserCore',
      id: 'gid://gitlab/User/1',
      avatarUrl:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
      name: 'Administrator',
      username: 'root',
      webUrl: '/root',
    },
  },
};

export const currentUserNullResponse = {
  data: {
    currentUser: null,
  },
};

export const mockLabels = [
  {
    __typename: 'Label',
    id: 'gid://gitlab/Label/1',
    title: 'Label 1',
    description: '',
    color: '#f00',
    textColor: '#00f',
  },
  {
    __typename: 'Label',
    id: 'gid://gitlab/Label/2',
    title: 'Label 2',
    description: '',
    color: '#b00',
    textColor: '#00b',
  },
];

export const projectLabelsResponse = {
  data: {
    workspace: {
      id: '1',
      __typename: 'Project',
      labels: {
        nodes: mockLabels,
      },
    },
  },
};

export const mockParent = {
  parent: {
    id: 'gid://gitlab/Issue/1',
    iid: '5',
    title: 'Parent title',
  },
};
