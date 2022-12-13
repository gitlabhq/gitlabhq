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
    title: 'Label::2',
    description: '',
    color: '#b00',
    textColor: '#00b',
  },
];

export const workItemQueryResponse = {
  data: {
    workItem: {
      __typename: 'WorkItem',
      id: 'gid://gitlab/WorkItem/1',
      iid: '1',
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
          lastEditedAt: null,
          lastEditedBy: null,
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
          hasChildren: true,
          parent: {
            id: 'gid://gitlab/Issue/1',
            iid: '5',
            title: 'Parent title',
            confidential: false,
            webUrl: 'http://gdk.test/gitlab-org/gitlab/-/issues/1',
            workItemType: {
              id: 'gid://gitlab/WorkItems::Type/1',
              name: 'Issue',
              iconName: 'issue-type-issue',
            },
          },
          children: {
            nodes: [
              {
                id: 'gid://gitlab/WorkItem/444',
                createdAt: '2022-08-03T12:41:54Z',
                closedAt: null,
                confidential: false,
                title: '123',
                state: 'OPEN',
                workItemType: {
                  id: '1',
                  name: 'Task',
                  iconName: 'issue-type-task',
                },
                widgets: [
                  {
                    type: 'HIERARCHY',
                    hasChildren: false,
                  },
                ],
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
        iid: '1',
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
            type: 'HIERARCHY',
            children: {
              nodes: [
                {
                  id: 'gid://gitlab/WorkItem/444',
                  createdAt: '2022-08-03T12:41:54Z',
                  closedAt: null,
                  confidential: false,
                  title: '123',
                  state: 'OPEN',
                  workItemType: {
                    id: '1',
                    name: 'Task',
                    iconName: 'issue-type-task',
                  },
                },
              ],
            },
            __typename: 'WorkItemConnection',
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
    webUrl: 'http://gdk.test/gitlab-org/gitlab/-/issues/1',
    workItemType: {
      id: 'gid://gitlab/WorkItems::Type/1',
      name: 'Issue',
      iconName: 'issue-type-issue',
    },
  },
};

export const descriptionTextWithCheckboxes = `- [ ] todo 1\n- [ ] todo 2`;

export const descriptionHtmlWithCheckboxes = `
  <ul dir="auto" class="task-list" data-sourcepos"1:1-2:12">
    <li class="task-list-item" data-sourcepos="1:1-1:11">
      <input class="task-list-item-checkbox" type="checkbox"> todo 1
    </li>
    <li class="task-list-item" data-sourcepos="2:1-2:12">
      <input class="task-list-item-checkbox" type="checkbox"> todo 2
    </li>
  </ul>
`;

const taskType = {
  __typename: 'WorkItemType',
  id: 'gid://gitlab/WorkItems::Type/5',
  name: 'Task',
  iconName: 'issue-type-task',
};

export const objectiveType = {
  __typename: 'WorkItemType',
  id: 'gid://gitlab/WorkItems::Type/2411',
  name: 'Objective',
  iconName: 'issue-type-objective',
};

export const workItemResponseFactory = ({
  canUpdate = false,
  canDelete = false,
  allowsMultipleAssignees = true,
  assigneesWidgetPresent = true,
  datesWidgetPresent = true,
  labelsWidgetPresent = true,
  weightWidgetPresent = true,
  milestoneWidgetPresent = true,
  iterationWidgetPresent = true,
  confidential = false,
  canInviteMembers = false,
  allowsScopedLabels = false,
  lastEditedAt = null,
  lastEditedBy = null,
  withCheckboxes = false,
  parent = mockParent.parent,
  workItemType = taskType,
} = {}) => ({
  data: {
    workItem: {
      __typename: 'WorkItem',
      id: 'gid://gitlab/WorkItem/1',
      iid: 1,
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
      workItemType,
      userPermissions: {
        deleteWorkItem: canDelete,
        updateWorkItem: canUpdate,
      },
      widgets: [
        {
          __typename: 'WorkItemWidgetDescription',
          type: 'DESCRIPTION',
          description: withCheckboxes ? descriptionTextWithCheckboxes : 'some **great** text',
          descriptionHtml: withCheckboxes
            ? descriptionHtmlWithCheckboxes
            : '<p data-sourcepos="1:1-1:19" dir="auto">some <strong>great</strong> text</p>',
          lastEditedAt,
          lastEditedBy,
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
        labelsWidgetPresent
          ? {
              __typename: 'WorkItemWidgetLabels',
              type: 'LABELS',
              allowsScopedLabels,
              labels: {
                nodes: mockLabels,
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
        iterationWidgetPresent
          ? {
              __typename: 'WorkItemWidgetIteration',
              type: 'ITERATION',
              iteration: {
                description: null,
                id: 'gid://gitlab/Iteration/1215',
                iid: '182',
                title: 'Iteration default title',
                startDate: '2022-09-22',
                dueDate: '2022-09-30',
              },
            }
          : { type: 'MOCK TYPE' },
        milestoneWidgetPresent
          ? {
              __typename: 'WorkItemWidgetMilestone',
              type: 'MILESTONE',
              milestone: {
                expired: false,
                id: 'gid://gitlab/Milestone/30',
                title: 'v4.0',
              },
            }
          : { type: 'MOCK TYPE' },
        {
          __typename: 'WorkItemWidgetHierarchy',
          type: 'HIERARCHY',
          hasChildren: true,
          children: {
            nodes: [
              {
                id: 'gid://gitlab/WorkItem/444',
                createdAt: '2022-08-03T12:41:54Z',
                closedAt: null,
                confidential: false,
                title: '123',
                state: 'OPEN',
                workItemType: {
                  id: '1',
                  name: 'Task',
                  iconName: 'issue-type-task',
                },
                widgets: [
                  {
                    type: 'HIERARCHY',
                    hasChildren: false,
                  },
                ],
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
      __typename: 'Project',
      id: 'gid://gitlab/Project/2',
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
        iid: '1',
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
        iid: '1',
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
            lastEditedAt: '2022-09-21T06:18:42Z',
            lastEditedBy: {
              name: 'Administrator',
              webPath: '/root',
            },
          },
        ],
      },
      newWorkItem: {
        __typename: 'WorkItem',
        id: 'gid://gitlab/WorkItem/1000000',
        iid: '100',
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

export const workItemDescriptionSubscriptionResponse = {
  data: {
    issuableDescriptionUpdated: {
      id: 'gid://gitlab/WorkItem/1',
      widgets: [
        {
          __typename: 'WorkItemWidgetDescription',
          type: 'DESCRIPTION',
          description: 'New description',
          descriptionHtml: '<p>New description</p>',
          lastEditedAt: '2022-09-21T06:18:42Z',
          lastEditedBy: {
            id: 'gid://gitlab/User/2',
            name: 'Someone else',
            webPath: '/not-you',
          },
        },
      ],
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

export const workItemLabelsSubscriptionResponse = {
  data: {
    issuableLabelsUpdated: {
      id: 'gid://gitlab/WorkItem/1',
      widgets: [
        {
          __typename: 'WorkItemWidgetLabels',
          type: 'LABELS',
          allowsScopedLabels: false,
          labels: {
            nodes: mockLabels,
          },
        },
      ],
    },
  },
};

export const workItemIterationSubscriptionResponse = {
  data: {
    issuableIterationUpdated: {
      id: 'gid://gitlab/WorkItem/1',
      widgets: [
        {
          __typename: 'WorkItemWidgetIteration',
          iteration: {
            description: 'Iteration description',
            dueDate: '2022-07-29',
            id: 'gid://gitlab/Iteration/1125',
            iid: '95',
            startDate: '2022-06-22',
            title: 'Iteration subcription title',
          },
        },
      ],
    },
  },
};

export const workItemMilestoneSubscriptionResponse = {
  data: {
    issuableMilestoneUpdated: {
      id: 'gid://gitlab/WorkItem/1',
      widgets: [
        {
          __typename: 'WorkItemWidgetMilestone',
          type: 'MILESTONE',
          milestone: {
            id: 'gid://gitlab/Milestone/1125',
            expired: false,
            title: 'Milestone title',
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
        name: 'Issue',
        iconName: 'issue-type-issue',
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
          hasChildren: false,
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
        name: 'Issue',
        iconName: 'issue-type-issue',
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
          hasChildren: true,
          children: {
            nodes: [
              {
                id: 'gid://gitlab/WorkItem/2',
                iid: '2',
                workItemType: {
                  id: 'gid://gitlab/WorkItems::Type/5',
                  name: 'Task',
                  iconName: 'issue-type-task',
                  __typename: 'WorkItemType',
                },
                title: 'xyz',
                state: 'OPEN',
                confidential: false,
                createdAt: '2022-08-03T12:41:54Z',
                closedAt: null,
                widgets: [
                  {
                    type: 'HIERARCHY',
                    hasChildren: false,
                  },
                ],
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
  iid: '4',
  workItemType: {
    id: 'gid://gitlab/WorkItems::Type/5',
    name: 'Task',
    iconName: 'issue-type-task',
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
  iid: '2',
  workItemType: {
    id: 'gid://gitlab/WorkItems::Type/5',
    name: 'Task',
    iconName: 'issue-type-task',
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
  iid: '3',
  workItemType: {
    id: 'gid://gitlab/WorkItems::Type/5',
    name: 'Task',
    iconName: 'issue-type-task',
    __typename: 'WorkItemType',
  },
  title: 'abc',
  state: 'CLOSED',
  confidential: false,
  createdAt: '2022-08-03T12:41:54Z',
  closedAt: '2022-08-12T13:07:52Z',
  __typename: 'WorkItem',
};

export const childrenWorkItems = [
  confidentialWorkItemTask,
  closedWorkItemTask,
  workItemTask,
  {
    id: 'gid://gitlab/WorkItem/5',
    iid: '5',
    workItemType: {
      id: 'gid://gitlab/WorkItems::Type/5',
      name: 'Task',
      iconName: 'issue-type-task',
      __typename: 'WorkItemType',
    },
    title: 'foobar',
    state: 'OPEN',
    confidential: false,
    createdAt: '2022-08-03T12:41:54Z',
    closedAt: null,
    __typename: 'WorkItem',
  },
];

export const workItemHierarchyResponse = {
  data: {
    workItem: {
      id: 'gid://gitlab/WorkItem/1',
      iid: '1',
      workItemType: {
        id: 'gid://gitlab/WorkItems::Type/6',
        name: 'Objective',
        iconName: 'issue-type-objective',
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
          hasChildren: true,
          children: {
            nodes: childrenWorkItems,
            __typename: 'WorkItemConnection',
          },
          __typename: 'WorkItemWidgetHierarchy',
        },
      ],
      __typename: 'WorkItem',
    },
  },
};

export const workItemObjectiveWithChild = {
  id: 'gid://gitlab/WorkItem/12',
  iid: '12',
  workItemType: {
    id: 'gid://gitlab/WorkItems::Type/2411',
    name: 'Objective',
    iconName: 'issue-type-objective',
    __typename: 'WorkItemType',
  },
  title: 'Objective',
  state: 'OPEN',
  confidential: false,
  createdAt: '2022-08-03T12:41:54Z',
  closedAt: null,
  widgets: [
    {
      type: 'HIERARCHY',
      hasChildren: true,
      __typename: 'WorkItemWidgetHierarchy',
    },
  ],
  __typename: 'WorkItem',
};

export const workItemHierarchyTreeResponse = {
  data: {
    workItem: {
      id: 'gid://gitlab/WorkItem/2',
      iid: '2',
      workItemType: {
        id: 'gid://gitlab/WorkItems::Type/2411',
        name: 'Objective',
        iconName: 'issue-type-objective',
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
          hasChildren: true,
          children: {
            nodes: [
              {
                id: 'gid://gitlab/WorkItem/13',
                iid: '13',
                workItemType: {
                  id: 'gid://gitlab/WorkItems::Type/2411',
                  name: 'Objective',
                  iconName: 'issue-type-objective',
                  __typename: 'WorkItemType',
                },
                title: 'Objective 2',
                state: 'OPEN',
                confidential: false,
                createdAt: '2022-08-03T12:41:54Z',
                closedAt: null,
                widgets: [
                  {
                    type: 'HIERARCHY',
                    hasChildren: true,
                    __typename: 'WorkItemWidgetHierarchy',
                  },
                ],
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

export const workItemHierarchyTreeFailureResponse = {
  data: {},
  errors: [
    {
      message: 'Something went wrong',
    },
  ],
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
        iid: '2',
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
            hasChildren: false,
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
        nodes: [
          {
            id: 'gid://gitlab/WorkItem/458',
            title: 'Task 1',
            state: 'OPEN',
            createdAt: '2022-08-03T12:41:54Z',
            __typename: 'WorkItem',
          },
          {
            id: 'gid://gitlab/WorkItem/459',
            title: 'Task 2',
            state: 'OPEN',
            createdAt: '2022-08-03T12:41:54Z',
            __typename: 'WorkItem',
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

export const mockIterationWidgetResponse = {
  description: 'Iteration description',
  dueDate: '2022-07-19',
  id: 'gid://gitlab/Iteration/1124',
  iid: '91',
  startDate: '2022-06-22',
  title: 'Iteration title widget',
};

export const groupIterationsResponse = {
  data: {
    workspace: {
      id: 'gid://gitlab/Group/22',
      attributes: {
        nodes: [
          {
            id: 'gid://gitlab/Iteration/1124',
            title: null,
            startDate: '2022-06-22',
            dueDate: '2022-07-19',
            webUrl: 'http://127.0.0.1:3000/groups/gitlab-org/-/iterations/1124',
            iterationCadence: {
              id: 'gid://gitlab/Iterations::Cadence/1101',
              title: 'Quod voluptates quidem ea eaque eligendi ex corporis.',
              __typename: 'IterationCadence',
            },
            __typename: 'Iteration',
            state: 'current',
          },
          {
            id: 'gid://gitlab/Iteration/1185',
            title: null,
            startDate: '2022-07-06',
            dueDate: '2022-07-19',
            webUrl: 'http://127.0.0.1:3000/groups/gitlab-org/-/iterations/1185',
            iterationCadence: {
              id: 'gid://gitlab/Iterations::Cadence/1144',
              title: 'Quo velit perspiciatis saepe aut omnis voluptas ab eos.',
              __typename: 'IterationCadence',
            },
            __typename: 'Iteration',
            state: 'current',
          },
          {
            id: 'gid://gitlab/Iteration/1194',
            title: null,
            startDate: '2022-07-06',
            dueDate: '2022-07-19',
            webUrl: 'http://127.0.0.1:3000/groups/gitlab-org/-/iterations/1194',
            iterationCadence: {
              id: 'gid://gitlab/Iterations::Cadence/1152',
              title:
                'Minima aut consequatur magnam vero doloremque accusamus maxime repellat voluptatem qui.',
              __typename: 'IterationCadence',
            },
            __typename: 'Iteration',
            state: 'current',
          },
        ],
        __typename: 'IterationConnection',
      },
      __typename: 'Group',
    },
  },
};

export const groupIterationsResponseWithNoIterations = {
  data: {
    workspace: {
      id: 'gid://gitlab/Group/22',
      attributes: {
        nodes: [],
        __typename: 'IterationConnection',
      },
      __typename: 'Group',
    },
  },
};

export const mockMilestoneWidgetResponse = {
  state: 'active',
  expired: false,
  id: 'gid://gitlab/Milestone/30',
  title: 'v4.0',
};

export const projectMilestonesResponse = {
  data: {
    workspace: {
      id: 'gid://gitlab/Project/1',
      attributes: {
        nodes: [
          {
            id: 'gid://gitlab/Milestone/5',
            title: 'v4.0',
            webUrl: '/gitlab-org/gitlab-test/-/milestones/5',
            dueDate: null,
            expired: false,
            __typename: 'Milestone',
            state: 'active',
          },
          {
            id: 'gid://gitlab/Milestone/4',
            title: 'v3.0',
            webUrl: '/gitlab-org/gitlab-test/-/milestones/4',
            dueDate: null,
            expired: false,
            __typename: 'Milestone',
            state: 'active',
          },
        ],
        __typename: 'MilestoneConnection',
      },
      __typename: 'Project',
    },
  },
};

export const projectMilestonesResponseWithNoMilestones = {
  data: {
    workspace: {
      id: 'gid://gitlab/Project/1',
      attributes: {
        nodes: [],
        __typename: 'MilestoneConnection',
      },
      __typename: 'Project',
    },
  },
};

export const projectWorkItemResponse = {
  data: {
    workspace: {
      id: 'gid://gitlab/Project/1',
      workItems: {
        nodes: [workItemQueryResponse.data.workItem],
      },
    },
  },
};
