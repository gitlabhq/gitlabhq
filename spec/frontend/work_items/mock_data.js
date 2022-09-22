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
      confidential: false,
      createdAt: '2022-08-03T12:41:54Z',
      closedAt: null,
      project: {
        __typename: 'Project',
        id: '1',
        fullPath: 'test-project-path',
      },
      workItemType: {
        __typename: 'WorkItemType',
        id: 'gid://gitlab/WorkItems::Type/5',
        name: 'Task',
        iconName: 'issue-type-task',
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
          canInviteMembers: true,
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
            confidential: false,
          },
          children: {
            nodes: [
              {
                id: 'gid://gitlab/WorkItem/444',
                createdAt: '2022-08-03T12:41:54Z',
                closedAt: null,
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
        confidential: false,
        createdAt: '2022-08-03T12:41:54Z',
        closedAt: null,
        project: {
          __typename: 'Project',
          id: '1',
          fullPath: 'test-project-path',
        },
        workItemType: {
          __typename: 'WorkItemType',
          id: 'gid://gitlab/WorkItems::Type/5',
          name: 'Task',
          iconName: 'issue-type-task',
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
          {
            __typename: 'WorkItemWidgetAssignees',
            type: 'ASSIGNEES',
            allowsMultipleAssignees: true,
            canInviteMembers: true,
            assignees: {
              nodes: [mockAssignees[0]],
            },
          },
        ],
      },
    },
  },
};

export const updateWorkItemMutationErrorResponse = {
  data: {
    workItemUpdate: {
      __typename: 'WorkItemUpdatePayload',
      errors: ['Error!'],
      workItem: {},
    },
  },
};

export const mockParent = {
  parent: {
    id: 'gid://gitlab/Issue/1',
    iid: '5',
    title: 'Parent title',
    confidential: false,
  },
};

export const workItemResponseFactory = ({
  canUpdate = false,
  canDelete = false,
  allowsMultipleAssignees = true,
  assigneesWidgetPresent = true,
  datesWidgetPresent = true,
  weightWidgetPresent = true,
  confidential = false,
  canInviteMembers = false,
  parent = mockParent.parent,
} = {}) => ({
  data: {
    workItem: {
      __typename: 'WorkItem',
      id: 'gid://gitlab/WorkItem/1',
      title: 'Updated title',
      state: 'OPEN',
      description: 'description',
      confidential,
      createdAt: '2022-08-03T12:41:54Z',
      closedAt: null,
      project: {
        __typename: 'Project',
        id: '1',
        fullPath: 'test-project-path',
      },
      workItemType: {
        __typename: 'WorkItemType',
        id: 'gid://gitlab/WorkItems::Type/5',
        name: 'Task',
        iconName: 'issue-type-task',
      },
      userPermissions: {
        deleteWorkItem: canDelete,
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
              canInviteMembers,
              assignees: {
                nodes: mockAssignees,
              },
            }
          : { type: 'MOCK TYPE' },
        datesWidgetPresent
          ? {
              __typename: 'WorkItemWidgetStartAndDueDate',
              type: 'START_AND_DUE_DATE',
              dueDate: '2022-12-31',
              startDate: '2022-01-01',
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
                createdAt: '2022-08-03T12:41:54Z',
                closedAt: null,
              },
            ],
          },
          parent,
        },
      ],
    },
  },
});

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
        confidential: false,
        createdAt: '2022-08-03T12:41:54Z',
        closedAt: null,
        project: {
          __typename: 'Project',
          id: '1',
          fullPath: 'test-project-path',
        },
        workItemType: {
          __typename: 'WorkItemType',
          id: 'gid://gitlab/WorkItems::Type/5',
          name: 'Task',
          iconName: 'issue-type-task',
        },
        userPermissions: {
          deleteWorkItem: false,
          updateWorkItem: false,
        },
        widgets: [],
      },
      errors: [],
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
        confidential: false,
        createdAt: '2022-08-03T12:41:54Z',
        closedAt: null,
        project: {
          __typename: 'Project',
          id: '1',
          fullPath: 'test-project-path',
        },
        workItemType: {
          __typename: 'WorkItemType',
          id: 'gid://gitlab/WorkItems::Type/5',
          name: 'Task',
          iconName: 'issue-type-task',
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
        createdAt: '2022-08-03T12:41:54Z',
        closedAt: null,
        description: '',
        confidential: false,
        project: {
          __typename: 'Project',
          id: '1',
          fullPath: 'test-project-path',
        },
        workItemType: {
          __typename: 'WorkItemType',
          id: 'gid://gitlab/WorkItems::Type/5',
          name: 'Task',
          iconName: 'issue-type-task',
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

export const deleteWorkItemMutationErrorResponse = {
  data: {
    workItemDelete: {
      errors: ['Error'],
    },
  },
};

export const deleteWorkItemFromTaskMutationResponse = {
  data: {
    workItemDeleteTask: {
      workItem: { id: 123, descriptionHtml: 'updated work item desc' },
      errors: [],
    },
  },
};

export const deleteWorkItemFromTaskMutationErrorResponse = {
  data: {
    workItemDeleteTask: {
      workItem: { id: 123, descriptionHtml: 'updated work item desc' },
      errors: ['Error'],
    },
  },
};

export const workItemDatesSubscriptionResponse = {
  data: {
    issuableDatesUpdated: {
      id: 'gid://gitlab/WorkItem/1',
      widgets: [
        {
          __typename: 'WorkItemWidgetStartAndDueDate',
          dueDate: '2022-12-31',
          startDate: '2022-01-01',
        },
      ],
    },
  },
};

export const workItemTitleSubscriptionResponse = {
  data: {
    issuableTitleUpdated: {
      id: 'gid://gitlab/WorkItem/1',
      title: 'new title',
    },
  },
};

export const workItemWeightSubscriptionResponse = {
  data: {
    issuableWeightUpdated: {
      id: 'gid://gitlab/WorkItem/1',
      widgets: [
        {
          __typename: 'WorkItemWidgetWeight',
          weight: 1,
        },
      ],
    },
  },
};

export const workItemAssigneesSubscriptionResponse = {
  data: {
    issuableAssigneesUpdated: {
      id: 'gid://gitlab/WorkItem/1',
      widgets: [
        {
          __typename: 'WorkItemAssigneesWeight',
          assignees: {
            nodes: [mockAssignees[0]],
          },
        },
      ],
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
      createdAt: '2022-08-03T12:41:54Z',
      closedAt: null,
      project: {
        __typename: 'Project',
        id: '1',
        fullPath: 'test-project-path',
      },
      userPermissions: {
        deleteWorkItem: false,
        updateWorkItem: false,
      },
      confidential: false,
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

export const workItemHierarchyNoUpdatePermissionResponse = {
  data: {
    workItem: {
      id: 'gid://gitlab/WorkItem/1',
      workItemType: {
        id: 'gid://gitlab/WorkItems::Type/6',
        __typename: 'WorkItemType',
      },
      title: 'New title',
      userPermissions: {
        deleteWorkItem: false,
        updateWorkItem: false,
      },
      project: {
        __typename: 'Project',
        id: '1',
        fullPath: 'test-project-path',
      },
      confidential: false,
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
                confidential: false,
                createdAt: '2022-08-03T12:41:54Z',
                closedAt: null,
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

export const workItemTask = {
  id: 'gid://gitlab/WorkItem/4',
  workItemType: {
    id: 'gid://gitlab/WorkItems::Type/5',
    __typename: 'WorkItemType',
  },
  title: 'bar',
  state: 'OPEN',
  confidential: false,
  createdAt: '2022-08-03T12:41:54Z',
  closedAt: null,
  __typename: 'WorkItem',
};

export const confidentialWorkItemTask = {
  id: 'gid://gitlab/WorkItem/2',
  workItemType: {
    id: 'gid://gitlab/WorkItems::Type/5',
    __typename: 'WorkItemType',
  },
  title: 'xyz',
  state: 'OPEN',
  confidential: true,
  createdAt: '2022-08-03T12:41:54Z',
  closedAt: null,
  __typename: 'WorkItem',
};

export const closedWorkItemTask = {
  id: 'gid://gitlab/WorkItem/3',
  workItemType: {
    id: 'gid://gitlab/WorkItems::Type/5',
    __typename: 'WorkItemType',
  },
  title: 'abc',
  state: 'CLOSED',
  confidential: false,
  createdAt: '2022-08-03T12:41:54Z',
  closedAt: '2022-08-12T13:07:52Z',
  __typename: 'WorkItem',
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
      userPermissions: {
        deleteWorkItem: true,
        updateWorkItem: true,
      },
      confidential: false,
      project: {
        __typename: 'Project',
        id: '1',
        fullPath: 'test-project-path',
      },
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
              confidentialWorkItemTask,
              closedWorkItemTask,
              workItemTask,
              {
                id: 'gid://gitlab/WorkItem/5',
                workItemType: {
                  id: 'gid://gitlab/WorkItems::Type/5',
                  __typename: 'WorkItemType',
                },
                title: 'foobar',
                state: 'OPEN',
                confidential: false,
                createdAt: '2022-08-03T12:41:54Z',
                closedAt: null,
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
        __typename: 'WorkItem',
        workItemType: {
          __typename: 'WorkItemType',
          id: 'gid://gitlab/WorkItems::Type/1',
          name: 'Issue',
          iconName: 'issue-type-issue',
        },
        userPermissions: {
          deleteWorkItem: true,
          updateWorkItem: true,
        },
        description: null,
        id: 'gid://gitlab/WorkItem/2',
        state: 'OPEN',
        title: 'Foo',
        confidential: false,
        createdAt: '2022-08-03T12:41:54Z',
        closedAt: null,
        project: {
          __typename: 'Project',
          id: '1',
          fullPath: 'test-project-path',
        },
        widgets: [
          {
            __typename: 'WorkItemWidgetHierarchy',
            type: 'HIERARCHY',
            parent: null,
            children: {
              nodes: [],
            },
          },
        ],
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
              createdAt: '2022-08-03T12:41:54Z',
            },
          },
          {
            node: {
              id: 'gid://gitlab/WorkItem/459',
              title: 'Task 2',
              state: 'OPEN',
              createdAt: '2022-08-03T12:41:54Z',
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
        pageInfo: {
          hasNextPage: false,
          endCursor: null,
          startCursor: null,
        },
      },
    },
  },
};

export const projectMembersResponseWithCurrentUserWithNextPage = {
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
        pageInfo: {
          hasNextPage: true,
          endCursor: 'endCursor',
          startCursor: 'startCursor',
        },
      },
    },
  },
};

export const projectMembersResponseWithNoMatchingUsers = {
  data: {
    workspace: {
      id: '1',
      __typename: 'Project',
      users: {
        nodes: [],
        pageInfo: {
          endCursor: null,
          hasNextPage: false,
          startCursor: null,
        },
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
