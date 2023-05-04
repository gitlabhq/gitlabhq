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

export const mockMilestone = {
  __typename: 'Milestone',
  id: 'gid://gitlab/Milestone/30',
  title: 'v4.0',
  state: 'active',
  expired: false,
  startDate: '2022-10-17',
  dueDate: '2022-10-24',
};

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
      updatedAt: null,
      closedAt: null,
      author: {
        avatarUrl: 'http://127.0.0.1:3000/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
        id: 'gid://gitlab/User/1',
        name: 'Administrator',
        username: 'root',
        webUrl: 'http://127.0.0.1:3000/root',
        __typename: 'UserCore',
      },
      project: {
        __typename: 'Project',
        id: '1',
        fullPath: 'test-project-path',
        archived: false,
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
        setWorkItemMetadata: false,
        __typename: 'WorkItemPermissions',
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
                iid: '4',
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
        updatedAt: '2022-08-08T12:41:54Z',
        closedAt: null,
        author: {
          ...mockAssignees[0],
        },
        project: {
          __typename: 'Project',
          id: '1',
          fullPath: 'test-project-path',
          archived: false,
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
          setWorkItemMetadata: false,
          __typename: 'WorkItemPermissions',
        },
        widgets: [
          {
            type: 'HIERARCHY',
            children: {
              nodes: [
                {
                  id: 'gid://gitlab/WorkItem/444',
                  iid: '4',
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

export const convertWorkItemMutationErrorResponse = {
  data: {
    workItemConvert: {
      __typename: 'WorkItemConvertPayload',
      errors: ['Error!'],
      workItem: {},
    },
  },
};

export const convertWorkItemMutationResponse = {
  data: {
    workItemConvert: {
      __typename: 'WorkItemConvertPayload',
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
        updatedAt: '2022-08-08T12:41:54Z',
        closedAt: null,
        author: {
          ...mockAssignees[0],
        },
        project: {
          __typename: 'Project',
          id: '1',
          fullPath: 'test-project-path',
          archived: false,
        },
        workItemType: {
          __typename: 'WorkItemType',
          id: 'gid://gitlab/WorkItems::Type/4',
          name: 'Objective',
          iconName: 'issue-type-objective',
        },
        userPermissions: {
          deleteWorkItem: false,
          updateWorkItem: false,
          setWorkItemMetadata: false,
          __typename: 'WorkItemPermissions',
        },
        widgets: [
          {
            type: 'HIERARCHY',
            children: {
              nodes: [
                {
                  id: 'gid://gitlab/WorkItem/444',
                  iid: '4',
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
  notificationsWidgetPresent = true,
  subscribed = true,
  allowsMultipleAssignees = true,
  assigneesWidgetPresent = true,
  datesWidgetPresent = true,
  weightWidgetPresent = true,
  progressWidgetPresent = true,
  milestoneWidgetPresent = true,
  iterationWidgetPresent = true,
  healthStatusWidgetPresent = true,
  notesWidgetPresent = true,
  confidential = false,
  canInviteMembers = false,
  labelsWidgetPresent = true,
  labels = mockLabels,
  allowsScopedLabels = false,
  lastEditedAt = null,
  lastEditedBy = null,
  withCheckboxes = false,
  parent = mockParent.parent,
  workItemType = taskType,
  author = mockAssignees[0],
  createdAt = '2022-08-03T12:41:54Z',
  updatedAt = '2022-08-08T12:32:54Z',
} = {}) => ({
  data: {
    workItem: {
      __typename: 'WorkItem',
      id: 'gid://gitlab/WorkItem/1',
      iid: '1',
      title: 'Updated title',
      state: 'OPEN',
      description: 'description',
      confidential,
      createdAt,
      updatedAt,
      closedAt: null,
      author,
      project: {
        __typename: 'Project',
        id: '1',
        fullPath: 'test-project-path',
        archived: false,
      },
      workItemType,
      userPermissions: {
        deleteWorkItem: canDelete,
        updateWorkItem: canUpdate,
        setWorkItemMetadata: canUpdate,
        __typename: 'WorkItemPermissions',
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
                nodes: labels,
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
        progressWidgetPresent
          ? {
              __typename: 'WorkItemWidgetProgress',
              type: 'PROGRESS',
              progress: 0,
            }
          : { type: 'MOCK TYPE' },
        milestoneWidgetPresent
          ? {
              __typename: 'WorkItemWidgetMilestone',
              type: 'MILESTONE',
              milestone: mockMilestone,
            }
          : { type: 'MOCK TYPE' },
        healthStatusWidgetPresent
          ? {
              __typename: 'WorkItemWidgetHealthStatus',
              type: 'HEALTH_STATUS',
              healthStatus: 'onTrack',
            }
          : { type: 'MOCK TYPE' },
        notesWidgetPresent
          ? {
              __typename: 'WorkItemWidgetNotes',
              type: 'NOTES',
              discussions: {
                pageInfo: {
                  hasNextPage: true,
                  hasPreviousPage: false,
                  startCursor: null,
                  endCursor:
                    'eyJjcmVhdGVkX2F0IjoiMjAyMi0xMS0xNCAwNDoxOTowMC4wOTkxMTcwMDAgKzAwMDAiLCJpZCI6IjQyNyIsIl9rZCI6Im4ifQ==',
                  __typename: 'PageInfo',
                },
                nodes: [],
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
                iid: '5',
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
        notesWidgetPresent
          ? {
              __typename: 'WorkItemWidgetNotes',
              type: 'NOTES',
            }
          : { type: 'MOCK TYPE' },
        notificationsWidgetPresent
          ? {
              __typename: 'WorkItemWidgetNotifications',
              type: 'NOTIFICATIONS',
              subscribed,
            }
          : { type: 'MOCK TYPE' },
      ],
    },
  },
});

export const workItemByIidResponseFactory = (options) => {
  const response = workItemResponseFactory(options);
  return {
    data: {
      workspace: {
        __typename: 'Project',
        id: 'gid://gitlab/Project/1',
        workItems: {
          nodes: [response.data.workItem],
        },
      },
    },
  };
};

export const getIssueDetailsResponse = ({ confidential = false } = {}) => ({
  data: {
    issue: {
      id: 'gid://gitlab/Issue/4',
      confidential,
      iteration: {
        id: 'gid://gitlab/Iteration/1124',
        __typename: 'Iteration',
      },
      milestone: {
        id: 'gid://gitlab/Milestone/28',
        __typename: 'Milestone',
      },
      __typename: 'Issue',
    },
    __typename: 'Project',
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
          { id: 'gid://gitlab/WorkItems::Type/4', name: 'Objective' },
          { id: 'gid://gitlab/WorkItems::Type/5', name: 'Key Result' },
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
        updatedAt: null,
        closedAt: null,
        author: {
          ...mockAssignees[0],
        },
        project: {
          __typename: 'Project',
          id: '1',
          fullPath: 'test-project-path',
          archived: false,
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
          setWorkItemMetadata: false,
          __typename: 'WorkItemPermissions',
        },
        widgets: [],
      },
      errors: [],
    },
  },
};

export const createWorkItemMutationErrorResponse = {
  data: {
    workItemCreate: {
      __typename: 'WorkItemCreatePayload',
      workItem: null,
      errors: ['an error'],
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
          archived: false,
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
          setWorkItemMetadata: false,
          __typename: 'WorkItemPermissions',
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
          archived: false,
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
          setWorkItemMetadata: false,
          __typename: 'WorkItemPermissions',
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

export const workItemHealthStatusSubscriptionResponse = {
  data: {
    issuableHealthStatusUpdated: {
      id: 'gid://gitlab/WorkItem/1',
      widgets: [
        {
          __typename: 'WorkItemWidgetHealthStatus',
          healthStatus: 'needsAttention',
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
      iid: '1',
      state: 'OPEN',
      workItemType: {
        id: 'gid://gitlab/WorkItems::Type/1',
        name: 'Issue',
        iconName: 'issue-type-issue',
        __typename: 'WorkItemType',
      },
      title: 'New title',
      description: '',
      createdAt: '2022-08-03T12:41:54Z',
      updatedAt: null,
      closedAt: null,
      author: mockAssignees[0],
      project: {
        __typename: 'Project',
        id: '1',
        fullPath: 'test-project-path',
        archived: false,
      },
      userPermissions: {
        deleteWorkItem: false,
        updateWorkItem: false,
        setWorkItemMetadata: false,
        __typename: 'WorkItemPermissions',
      },
      confidential: false,
      widgets: [
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
      iid: '1',
      state: 'OPEN',
      workItemType: {
        id: 'gid://gitlab/WorkItems::Type/6',
        name: 'Issue',
        iconName: 'issue-type-issue',
        __typename: 'WorkItemType',
      },
      title: 'New title',
      description: '',
      createdAt: '2022-08-03T12:41:54Z',
      updatedAt: null,
      closedAt: null,
      author: mockAssignees[0],
      userPermissions: {
        deleteWorkItem: false,
        updateWorkItem: false,
        setWorkItemMetadata: false,
        __typename: 'WorkItemPermissions',
      },
      project: {
        __typename: 'Project',
        id: '1',
        fullPath: 'test-project-path',
        archived: false,
      },
      confidential: false,
      widgets: [
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
  widgets: [],
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
  widgets: [],
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
  widgets: [],
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
    widgets: [],
    __typename: 'WorkItem',
  },
];

export const workItemHierarchyResponse = {
  data: {
    workItem: {
      id: 'gid://gitlab/WorkItem/1',
      iid: '1',
      workItemType: {
        id: 'gid://gitlab/WorkItems::Type/1',
        name: 'Issue',
        iconName: 'issue-type-issue',
        __typename: 'WorkItemType',
      },
      title: 'New title',
      userPermissions: {
        deleteWorkItem: true,
        updateWorkItem: true,
        setWorkItemMetadata: true,
        __typename: 'WorkItemPermissions',
      },
      author: {
        ...mockAssignees[0],
      },
      confidential: false,
      project: {
        __typename: 'Project',
        id: '1',
        fullPath: 'test-project-path',
        archived: false,
      },
      description: 'Issue description',
      state: 'OPEN',
      createdAt: '2022-08-03T12:41:54Z',
      updatedAt: null,
      closedAt: null,
      widgets: [
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

export const workItemObjectiveMetadataWidgets = {
  ASSIGNEES: {
    type: 'ASSIGNEES',
    __typename: 'WorkItemWidgetAssignees',
    canInviteMembers: true,
    allowsMultipleAssignees: true,
    assignees: {
      __typename: 'UserCoreConnection',
      nodes: mockAssignees,
    },
  },
  HEALTH_STATUS: {
    type: 'HEALTH_STATUS',
    __typename: 'WorkItemWidgetHealthStatus',
    healthStatus: 'onTrack',
  },
  LABELS: {
    type: 'LABELS',
    __typename: 'WorkItemWidgetLabels',
    allowsScopedLabels: true,
    labels: {
      __typename: 'LabelConnection',
      nodes: mockLabels,
    },
  },
  MILESTONE: {
    type: 'MILESTONE',
    __typename: 'WorkItemWidgetMilestone',
    milestone: mockMilestone,
  },
  PROGRESS: {
    type: 'PROGRESS',
    __typename: 'WorkItemWidgetProgress',
    progress: 10,
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
  project: {
    __typename: 'Project',
    id: '1',
    fullPath: 'test-project-path',
    archived: false,
  },
  userPermissions: {
    deleteWorkItem: true,
    updateWorkItem: true,
    setWorkItemMetadata: true,
    __typename: 'WorkItemPermissions',
  },
  author: {
    ...mockAssignees[0],
  },
  title: 'Objective',
  description: 'Objective description',
  state: 'OPEN',
  confidential: false,
  createdAt: '2022-08-03T12:41:54Z',
  updatedAt: null,
  closedAt: null,
  widgets: [
    {
      type: 'HIERARCHY',
      hasChildren: true,
      parent: null,
      children: {
        nodes: [],
      },
      __typename: 'WorkItemWidgetHierarchy',
    },
    workItemObjectiveMetadataWidgets.PROGRESS,
    workItemObjectiveMetadataWidgets.HEALTH_STATUS,
    workItemObjectiveMetadataWidgets.MILESTONE,
    workItemObjectiveMetadataWidgets.ASSIGNEES,
    workItemObjectiveMetadataWidgets.LABELS,
  ],
  __typename: 'WorkItem',
};

export const workItemObjectiveNoMetadata = {
  ...workItemObjectiveWithChild,
  widgets: [
    {
      type: 'HIERARCHY',
      hasChildren: true,
      __typename: 'WorkItemWidgetHierarchy',
    },
    {
      __typename: 'WorkItemWidgetProgress',
      type: 'PROGRESS',
      progress: null,
    },
    {
      __typename: 'WorkItemWidgetMilestone',
      type: 'MILESTONE',
      milestone: null,
    },
  ],
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
        setWorkItemMetadata: true,
        __typename: 'WorkItemPermissions',
      },
      confidential: false,
      project: {
        __typename: 'Project',
        id: '1',
        fullPath: 'test-project-path',
        archived: false,
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

export const changeIndirectWorkItemParentMutationResponse = {
  data: {
    workItemUpdate: {
      workItem: {
        __typename: 'WorkItem',
        workItemType: {
          id: 'gid://gitlab/WorkItems::Type/2411',
          name: 'Objective',
          iconName: 'issue-type-objective',
          __typename: 'WorkItemType',
        },
        userPermissions: {
          deleteWorkItem: true,
          updateWorkItem: true,
          setWorkItemMetadata: true,
          __typename: 'WorkItemPermissions',
        },
        description: null,
        id: 'gid://gitlab/WorkItem/13',
        iid: '13',
        state: 'OPEN',
        title: 'Objective 2',
        confidential: false,
        createdAt: '2022-08-03T12:41:54Z',
        updatedAt: null,
        closedAt: null,
        author: {
          ...mockAssignees[0],
        },
        project: {
          __typename: 'Project',
          id: '1',
          fullPath: 'test-project-path',
          archived: false,
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

export const workItemUpdateFailureResponse = {
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
          setWorkItemMetadata: true,
          __typename: 'WorkItemPermissions',
        },
        description: null,
        id: 'gid://gitlab/WorkItem/2',
        iid: '2',
        state: 'OPEN',
        title: 'Foo',
        confidential: false,
        createdAt: '2022-08-03T12:41:54Z',
        updatedAt: null,
        closedAt: null,
        author: {
          ...mockAssignees[0],
        },
        project: {
          __typename: 'Project',
          id: '1',
          fullPath: 'test-project-path',
          archived: false,
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
            confidential: false,
            __typename: 'WorkItem',
          },
          {
            id: 'gid://gitlab/WorkItem/459',
            title: 'Task 2',
            state: 'OPEN',
            createdAt: '2022-08-03T12:41:54Z',
            confidential: false,
            __typename: 'WorkItem',
          },
          {
            id: 'gid://gitlab/WorkItem/460',
            title: 'Task 3',
            state: 'OPEN',
            createdAt: '2022-08-03T12:41:54Z',
            confidential: true,
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
      __typename: 'Project',
    },
  },
};

export const mockWorkItemNotesResponse = {
  data: {
    workItem: {
      id: 'gid://gitlab/WorkItem/1',
      iid: '60',
      widgets: [
        {
          __typename: 'WorkItemWidgetIteration',
        },
        {
          __typename: 'WorkItemWidgetWeight',
        },
        {
          __typename: 'WorkItemWidgetAssignees',
        },
        {
          __typename: 'WorkItemWidgetLabels',
        },
        {
          __typename: 'WorkItemWidgetDescription',
        },
        {
          __typename: 'WorkItemWidgetHierarchy',
        },
        {
          __typename: 'WorkItemWidgetStartAndDueDate',
        },
        {
          __typename: 'WorkItemWidgetMilestone',
        },
        {
          type: 'NOTES',
          discussions: {
            pageInfo: {
              hasNextPage: false,
              hasPreviousPage: false,
              startCursor: null,
              endCursor: null,
              __typename: 'PageInfo',
            },
            nodes: [
              {
                id: 'gid://gitlab/Discussion/8bbc4890b6ff0f2cde93a5a0947cd2b8a13d3b6e',
                notes: {
                  nodes: [
                    {
                      id: 'gid://gitlab/Note/2428',
                      body: 'added #31 as parent issue',
                      bodyHtml:
                        '<p data-sourcepos="1:1-1:25" dir="auto">added <a href="/flightjs/Flight/-/issues/31" data-reference-type="issue" data-original="#31" data-link="false" data-link-reference="false" data-project="6" data-issue="224" data-project-path="flightjs/Flight" data-iid="31" data-issue-type="issue" data-container=body data-placement="top" title="Perferendis est quae totam quia laborum tempore ut voluptatem." class="gfm gfm-issue">#31</a> as parent issue</p>',
                      systemNoteIconName: 'link',
                      createdAt: '2022-11-14T04:18:59Z',
                      lastEditedAt: null,
                      url:
                        'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37?iid_path=true#note_199',
                      lastEditedBy: null,
                      system: true,
                      internal: false,
                      discussion: {
                        id: 'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da12723561234',
                      },
                      userPermissions: {
                        adminNote: false,
                        awardEmoji: true,
                        readNote: true,
                        createNote: true,
                        resolveNote: true,
                        repositionNote: true,
                        __typename: 'NotePermissions',
                      },
                      author: {
                        avatarUrl:
                          'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                        id: 'gid://gitlab/User/1',
                        name: 'Administrator',
                        username: 'root',
                        webUrl: 'http://127.0.0.1:3000/root',
                        __typename: 'UserCore',
                      },
                      __typename: 'Note',
                    },
                  ],
                  __typename: 'NoteConnection',
                },
                __typename: 'Discussion',
              },
              {
                id: 'gid://gitlab/Discussion/7b08b89a728a5ceb7de8334246837ba1d07270dc',
                notes: {
                  nodes: [
                    {
                      id: 'gid://gitlab/MilestoneNote/0f2f195ec0d1ef95ee9d5b10446b8e96a7d83864',
                      body: 'changed milestone to %v4.0',
                      bodyHtml:
                        '<p data-sourcepos="1:1-1:23" dir="auto">changed milestone to <a href="/flightjs/Flight/-/milestones/5" data-reference-type="milestone" data-original="%5" data-link="false" data-link-reference="false" data-project="6" data-milestone="30" data-container=body data-placement="top" title="" class="gfm gfm-milestone has-tooltip">%v4.0</a></p>',
                      systemNoteIconName: 'clock',
                      createdAt: '2022-11-14T04:18:59Z',
                      lastEditedAt: null,
                      url:
                        'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37?iid_path=true#note_201',
                      lastEditedBy: null,
                      system: true,
                      internal: false,
                      discussion: {
                        id: 'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da12723565678',
                      },
                      userPermissions: {
                        adminNote: false,
                        awardEmoji: true,
                        readNote: true,
                        createNote: true,
                        resolveNote: true,
                        repositionNote: true,
                        __typename: 'NotePermissions',
                      },
                      author: {
                        avatarUrl:
                          'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                        id: 'gid://gitlab/User/1',
                        name: 'Administrator',
                        username: 'root',
                        webUrl: 'http://127.0.0.1:3000/root',
                        __typename: 'UserCore',
                      },
                      __typename: 'Note',
                    },
                  ],
                  __typename: 'NoteConnection',
                },
                __typename: 'Discussion',
              },
              {
                id: 'gid://gitlab/Discussion/0f2f195ec0d1ef95ee9d5b10446b8e96a7d83864',
                notes: {
                  nodes: [
                    {
                      id: 'gid://gitlab/WeightNote/0f2f195ec0d1ef95ee9d5b10446b8e96a9883864',
                      body: 'changed weight to **89**',
                      bodyHtml: '<p dir="auto">changed weight to <strong>89</strong></p>',
                      systemNoteIconName: 'weight',
                      createdAt: '2022-11-25T07:16:20Z',
                      lastEditedAt: null,
                      url:
                        'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37?iid_path=true#note_202',
                      lastEditedBy: null,
                      system: true,
                      internal: false,
                      discussion: {
                        id: 'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da12723560987',
                      },
                      userPermissions: {
                        adminNote: false,
                        awardEmoji: true,
                        readNote: true,
                        createNote: true,
                        resolveNote: true,
                        repositionNote: true,
                        __typename: 'NotePermissions',
                      },
                      author: {
                        avatarUrl:
                          'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                        id: 'gid://gitlab/User/1',
                        name: 'Administrator',
                        username: 'root',
                        webUrl: 'http://127.0.0.1:3000/root',
                        __typename: 'UserCore',
                      },
                      __typename: 'Note',
                    },
                  ],
                  __typename: 'NoteConnection',
                },
                __typename: 'Discussion',
              },
            ],
            __typename: 'DiscussionConnection',
          },
          __typename: 'WorkItemWidgetNotes',
        },
      ],
      __typename: 'WorkItem',
    },
  },
};
export const mockWorkItemNotesByIidResponse = {
  data: {
    workspace: {
      id: 'gid://gitlab/Project/6',
      workItems: {
        nodes: [
          {
            id: 'gid://gitlab/WorkItem/600',
            iid: '51',
            widgets: [
              {
                __typename: 'WorkItemWidgetIteration',
              },
              {
                __typename: 'WorkItemWidgetWeight',
              },
              {
                __typename: 'WorkItemWidgetHealthStatus',
              },
              {
                __typename: 'WorkItemWidgetAssignees',
              },
              {
                __typename: 'WorkItemWidgetLabels',
              },
              {
                __typename: 'WorkItemWidgetDescription',
              },
              {
                __typename: 'WorkItemWidgetHierarchy',
              },
              {
                __typename: 'WorkItemWidgetStartAndDueDate',
              },
              {
                __typename: 'WorkItemWidgetMilestone',
              },
              {
                type: 'NOTES',
                discussions: {
                  pageInfo: {
                    hasNextPage: true,
                    hasPreviousPage: false,
                    startCursor: null,
                    endCursor:
                      'eyJjcmVhdGVkX2F0IjoiMjAyMi0xMS0xNCAwNDoxOTowMC4wOTkxMTcwMDAgKzAwMDAiLCJpZCI6IjQyNyIsIl9rZCI6Im4ifQ==',
                    __typename: 'PageInfo',
                  },
                  nodes: [
                    {
                      id: 'gid://gitlab/Discussion/8bbc4890b6ff0f2cde93a5a0947cd2b8a13d3b6e',
                      notes: {
                        nodes: [
                          {
                            id: 'gid://gitlab/Note/2428',
                            body: 'added as parent issue',
                            bodyHtml:
                              '\u003cp data-sourcepos="1:1-1:25" dir="auto"\u003eadded \u003ca href="/flightjs/Flight/-/issues/31" data-reference-type="issue" data-original="#31" data-link="false" data-link-reference="false" data-project="6" data-issue="224" data-project-path="flightjs/Flight" data-iid="31" data-issue-type="issue" data-container="body" data-placement="top" title="Perferendis est quae totam quia laborum tempore ut voluptatem." class="gfm gfm-issue"\u003e#31\u003c/a\u003e as parent issue\u003c/p\u003e',
                            systemNoteIconName: 'link',
                            createdAt: '2022-11-14T04:18:59Z',
                            lastEditedAt: null,
                            url:
                              'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37?iid_path=true#note_191',
                            lastEditedBy: null,
                            system: true,
                            internal: false,
                            discussion: {
                              id:
                                'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da12723561234',
                            },
                            userPermissions: {
                              adminNote: false,
                              awardEmoji: true,
                              readNote: true,
                              createNote: true,
                              resolveNote: true,
                              repositionNote: true,
                              __typename: 'NotePermissions',
                            },
                            author: {
                              id: 'gid://gitlab/User/1',
                              avatarUrl:
                                'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
                              name: 'Administrator',
                              username: 'root',
                              webUrl: 'http://127.0.0.1:3000/root',
                              __typename: 'UserCore',
                            },
                            __typename: 'Note',
                          },
                        ],
                        __typename: 'NoteConnection',
                      },
                      __typename: 'Discussion',
                    },
                    {
                      id: 'gid://gitlab/Discussion/7b08b89a728a5ceb7de8334246837ba1d07270dc',
                      notes: {
                        nodes: [
                          {
                            id:
                              'gid://gitlab/MilestoneNote/7b08b89a728a5ceb7de8334246837ba1d07270dc',
                            body: 'changed milestone to %v4.0',
                            bodyHtml:
                              '\u003cp data-sourcepos="1:1-1:23" dir="auto"\u003echanged milestone to \u003ca href="/flightjs/Flight/-/milestones/5" data-reference-type="milestone" data-original="%5" data-link="false" data-link-reference="false" data-project="6" data-milestone="30" data-container="body" data-placement="top" title="" class="gfm gfm-milestone has-tooltip"\u003e%v4.0\u003c/a\u003e\u003c/p\u003e',
                            systemNoteIconName: 'clock',
                            createdAt: '2022-11-14T04:18:59Z',
                            lastEditedAt: null,
                            url:
                              'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37?iid_path=true#note_191',
                            lastEditedBy: null,
                            system: true,
                            internal: false,
                            discussion: {
                              id:
                                'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da12723568765',
                            },
                            userPermissions: {
                              adminNote: false,
                              awardEmoji: true,
                              readNote: true,
                              createNote: true,
                              resolveNote: true,
                              repositionNote: true,
                              __typename: 'NotePermissions',
                            },
                            author: {
                              id: 'gid://gitlab/User/1',
                              avatarUrl:
                                'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
                              name: 'Administrator',
                              username: 'root',
                              webUrl: 'http://127.0.0.1:3000/root',
                              __typename: 'UserCore',
                            },
                            __typename: 'Note',
                          },
                        ],
                        __typename: 'NoteConnection',
                      },
                      __typename: 'Discussion',
                    },
                    {
                      id: 'gid://gitlab/Discussion/addbc177f7664699a135130ab05ffb78c57e4db3',
                      notes: {
                        nodes: [
                          {
                            id:
                              'gid://gitlab/IterationNote/addbc177f7664699a135130ab05ffb78c57e4db3',
                            body:
                              'changed iteration to Et autem debitis nam suscipit eos ut. Jul 13, 2022 - Jul 19, 2022',
                            bodyHtml:
                              '\u003cp data-sourcepos="1:1-1:36" dir="auto"\u003echanged iteration to \u003ca href="/groups/flightjs/-/iterations/5352" data-reference-type="iteration" data-original="*iteration:5352" data-link="false" data-link-reference="false" data-project="6" data-iteration="5352" data-container="body" data-placement="top" title="Iteration" class="gfm gfm-iteration has-tooltip"\u003eEt autem debitis nam suscipit eos ut. Jul 13, 2022 - Jul 19, 2022\u003c/a\u003e\u003c/p\u003e',
                            systemNoteIconName: 'iteration',
                            createdAt: '2022-11-14T04:19:00Z',
                            lastEditedAt: null,
                            url:
                              'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37?iid_path=true#note_191',
                            lastEditedBy: null,
                            system: true,
                            internal: false,
                            discussion: {
                              id:
                                'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da12723569876',
                            },
                            userPermissions: {
                              adminNote: false,
                              awardEmoji: true,
                              readNote: true,
                              createNote: true,
                              resolveNote: true,
                              repositionNote: true,
                              __typename: 'NotePermissions',
                            },
                            author: {
                              id: 'gid://gitlab/User/1',
                              avatarUrl:
                                'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
                              name: 'Administrator',
                              username: 'root',
                              webUrl: 'http://127.0.0.1:3000/root',
                              __typename: 'UserCore',
                            },
                            __typename: 'Note',
                          },
                        ],
                        __typename: 'NoteConnection',
                      },
                      __typename: 'Discussion',
                    },
                  ],
                  __typename: 'DiscussionConnection',
                },
                __typename: 'WorkItemWidgetNotes',
              },
            ],
            __typename: 'WorkItem',
          },
        ],
        __typename: 'WorkItemConnection',
      },
      __typename: 'Project',
    },
  },
};
export const mockMoreWorkItemNotesResponse = {
  data: {
    workspace: {
      id: 'gid://gitlab/Project/6',
      workItems: {
        nodes: [
          {
            id: 'gid://gitlab/WorkItem/600',
            iid: '60',
            widgets: [
              {
                __typename: 'WorkItemWidgetIteration',
              },
              {
                __typename: 'WorkItemWidgetWeight',
              },
              {
                __typename: 'WorkItemWidgetAssignees',
              },
              {
                __typename: 'WorkItemWidgetLabels',
              },
              {
                __typename: 'WorkItemWidgetDescription',
              },
              {
                __typename: 'WorkItemWidgetHierarchy',
              },
              {
                __typename: 'WorkItemWidgetStartAndDueDate',
              },
              {
                __typename: 'WorkItemWidgetMilestone',
              },
              {
                type: 'NOTES',
                discussions: {
                  pageInfo: {
                    hasNextPage: true,
                    hasPreviousPage: false,
                    startCursor: null,
                    endCursor: 'endCursor',
                    __typename: 'PageInfo',
                  },
                  nodes: [
                    {
                      id: 'gid://gitlab/Discussion/8bbc4890b6ff0f2cde93a5a0947cd2b8a13d3b6e',
                      notes: {
                        nodes: [
                          {
                            id: 'gid://gitlab/Note/2428',
                            body: 'added #31 as parent issue',
                            bodyHtml:
                              '<p data-sourcepos="1:1-1:25" dir="auto">added <a href="/flightjs/Flight/-/issues/31" data-reference-type="issue" data-original="#31" data-link="false" data-link-reference="false" data-project="6" data-issue="224" data-project-path="flightjs/Flight" data-iid="31" data-issue-type="issue" data-container=body data-placement="top" title="Perferendis est quae totam quia laborum tempore ut voluptatem." class="gfm gfm-issue">#31</a> as parent issue</p>',
                            systemNoteIconName: 'link',
                            createdAt: '2022-11-14T04:18:59Z',
                            lastEditedAt: null,
                            url:
                              'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37?iid_path=true#note_191',
                            lastEditedBy: null,
                            system: true,
                            internal: false,
                            discussion: {
                              id:
                                'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da1112356a59e',
                            },
                            userPermissions: {
                              adminNote: false,
                              awardEmoji: true,
                              readNote: true,
                              createNote: true,
                              resolveNote: true,
                              repositionNote: true,
                              __typename: 'NotePermissions',
                            },
                            author: {
                              avatarUrl:
                                'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                              id: 'gid://gitlab/User/1',
                              name: 'Administrator',
                              username: 'root',
                              webUrl: 'http://127.0.0.1:3000/root',
                              __typename: 'UserCore',
                            },
                            __typename: 'Note',
                          },
                        ],
                        __typename: 'NoteConnection',
                      },
                      __typename: 'Discussion',
                    },
                    {
                      id: 'gid://gitlab/Discussion/7b08b89a728a5ceb7de8334246837ba1d07270dc',
                      notes: {
                        nodes: [
                          {
                            id:
                              'gid://gitlab/MilestoneNote/0f2f195ec0d1ef95ee9d5b10446b8e96a7d83823',
                            body: 'changed milestone to %v4.0',
                            bodyHtml:
                              '<p data-sourcepos="1:1-1:23" dir="auto">changed milestone to <a href="/flightjs/Flight/-/milestones/5" data-reference-type="milestone" data-original="%5" data-link="false" data-link-reference="false" data-project="6" data-milestone="30" data-container=body data-placement="top" title="" class="gfm gfm-milestone has-tooltip">%v4.0</a></p>',
                            systemNoteIconName: 'clock',
                            createdAt: '2022-11-14T04:18:59Z',
                            lastEditedAt: null,
                            url:
                              'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37?iid_path=true#note_191',
                            lastEditedBy: null,
                            system: true,
                            internal: false,
                            discussion: {
                              id:
                                'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da1272356a59e',
                            },
                            userPermissions: {
                              adminNote: false,
                              awardEmoji: true,
                              readNote: true,
                              createNote: true,
                              resolveNote: true,
                              repositionNote: true,
                              __typename: 'NotePermissions',
                            },
                            author: {
                              avatarUrl:
                                'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                              id: 'gid://gitlab/User/1',
                              name: 'Administrator',
                              username: 'root',
                              webUrl: 'http://127.0.0.1:3000/root',
                              __typename: 'UserCore',
                            },
                            __typename: 'Note',
                          },
                        ],
                        __typename: 'NoteConnection',
                      },
                      __typename: 'Discussion',
                    },
                    {
                      id: 'gid://gitlab/Discussion/0f2f195ec0d1ef95ee9d5b10446b8e96a7d83864',
                      notes: {
                        nodes: [
                          {
                            id: 'gid://gitlab/WeightNote/0f2f195ec0d1ef95ee9d5b10446b8e96a7d83864',
                            body: 'changed weight to **89**',
                            bodyHtml: '<p dir="auto">changed weight to <strong>89</strong></p>',
                            systemNoteIconName: 'weight',
                            createdAt: '2022-11-25T07:16:20Z',
                            lastEditedAt: null,
                            url:
                              'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37?iid_path=true#note_191',
                            lastEditedBy: null,
                            system: true,
                            internal: false,
                            discussion: {
                              id:
                                'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da12723569876',
                            },
                            userPermissions: {
                              adminNote: false,
                              awardEmoji: true,
                              readNote: true,
                              createNote: true,
                              resolveNote: true,
                              repositionNote: true,
                              __typename: 'NotePermissions',
                            },
                            author: {
                              avatarUrl:
                                'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                              id: 'gid://gitlab/User/1',
                              name: 'Administrator',
                              username: 'root',
                              webUrl: 'http://127.0.0.1:3000/root',
                              __typename: 'UserCore',
                            },
                            __typename: 'Note',
                          },
                        ],
                        __typename: 'NoteConnection',
                      },
                      __typename: 'Discussion',
                    },
                  ],
                  __typename: 'DiscussionConnection',
                },
                __typename: 'WorkItemWidgetNotes',
              },
            ],
            __typename: 'WorkItem',
          },
        ],
      },
    },
  },
};

export const createWorkItemNoteResponse = {
  data: {
    createNote: {
      errors: [],
      note: {
        id: 'gid://gitlab/Note/569',
        discussion: {
          id: 'gid://gitlab/Discussion/c872ba2d7d3eb780d2255138d67ca8b04f65b122',
          notes: {
            nodes: [
              {
                id: 'gid://gitlab/Note/569',
                body: 'Main comment',
                bodyHtml: '<p data-sourcepos="1:1-1:9" dir="auto">Main comment</p>',
                system: false,
                internal: false,
                systemNoteIconName: null,
                createdAt: '2023-01-25T04:49:46Z',
                lastEditedAt: null,
                url: 'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37?iid_path=true#note_191',
                lastEditedBy: null,
                discussion: {
                  id: 'gid://gitlab/Discussion/c872ba2d7d3eb780d2255138d67ca8b04f65b122',
                  __typename: 'Discussion',
                },
                author: {
                  id: 'gid://gitlab/User/1',
                  avatarUrl:
                    'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                  name: 'Administrator',
                  username: 'root',
                  webUrl: 'http://127.0.0.1:3000/root',
                  __typename: 'UserCore',
                },
                userPermissions: {
                  adminNote: true,
                  awardEmoji: true,
                  readNote: true,
                  createNote: true,
                  resolveNote: true,
                  repositionNote: true,
                  __typename: 'NotePermissions',
                },
                __typename: 'Note',
              },
            ],
            __typename: 'NoteConnection',
          },
          __typename: 'Discussion',
        },
        body: 'Latest 22',
        bodyHtml: '<p data-sourcepos="1:1-1:9" dir="auto">Latest 22</p>',
        __typename: 'Note',
      },
      __typename: 'CreateNotePayload',
    },
  },
};

export const mockWorkItemCommentNote = {
  id: 'gid://gitlab/Note/158',
  body: 'How are you ? what do you think about this ?',
  bodyHtml:
    '<p data-sourcepos="1:1-1:76" dir="auto"><gl-emoji title="waving hand sign" data-name="wave" data-unicode-version="6.0">👋</gl-emoji> Hi <a href="/fredda.brekke" data-reference-type="user" data-user="3" data-container="body" data-placement="top" class="gfm gfm-project_member js-user-link" title="Sherie Nitzsche">@fredda.brekke</a> How are you ? what do you think about this ? <gl-emoji title="person with folded hands" data-name="pray" data-unicode-version="6.0">🙏</gl-emoji></p>',
  systemNoteIconName: false,
  createdAt: '2022-11-25T07:16:20Z',
  lastEditedAt: null,
  url: 'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37?iid_path=true#note_191',
  lastEditedBy: null,
  system: false,
  internal: false,
  discussion: {
    id: 'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da12723569876',
  },
  userPermissions: {
    adminNote: false,
    awardEmoji: true,
    readNote: true,
    createNote: true,
    resolveNote: true,
    repositionNote: true,
    __typename: 'NotePermissions',
  },
  author: {
    avatarUrl: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
    id: 'gid://gitlab/User/1',
    name: 'Administrator',
    username: 'root',
    webUrl: 'http://127.0.0.1:3000/root',
    __typename: 'UserCore',
  },
};

export const mockWorkItemNotesResponseWithComments = {
  data: {
    workspace: {
      id: 'gid://gitlab/Project/6',
      workItems: {
        nodes: [
          {
            id: 'gid://gitlab/WorkItem/600',
            iid: '60',
            widgets: [
              {
                __typename: 'WorkItemWidgetIteration',
              },
              {
                __typename: 'WorkItemWidgetWeight',
              },
              {
                __typename: 'WorkItemWidgetAssignees',
              },
              {
                __typename: 'WorkItemWidgetLabels',
              },
              {
                __typename: 'WorkItemWidgetDescription',
              },
              {
                __typename: 'WorkItemWidgetHierarchy',
              },
              {
                __typename: 'WorkItemWidgetStartAndDueDate',
              },
              {
                __typename: 'WorkItemWidgetMilestone',
              },
              {
                type: 'NOTES',
                discussions: {
                  pageInfo: {
                    hasNextPage: false,
                    hasPreviousPage: false,
                    startCursor: null,
                    endCursor: null,
                    __typename: 'PageInfo',
                  },
                  nodes: [
                    {
                      id: 'gid://gitlab/Discussion/8bbc4890b6ff0f2cde93a5a0947cd2b8a13d3b6e',
                      notes: {
                        nodes: [
                          {
                            id: 'gid://gitlab/DiscussionNote/174',
                            body: 'Separate thread',
                            bodyHtml: '<p data-sourcepos="1:1-1:15" dir="auto">Separate thread</p>',
                            system: false,
                            internal: false,
                            systemNoteIconName: null,
                            createdAt: '2023-01-12T07:47:40Z',
                            lastEditedAt: null,
                            url:
                              'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37?iid_path=true#note_191',
                            lastEditedBy: null,
                            discussion: {
                              id:
                                'gid://gitlab/Discussion/2bb1162fd0d39297d1a68fdd7d4083d3780af0f3',
                              __typename: 'Discussion',
                            },
                            author: {
                              id: 'gid://gitlab/User/1',
                              avatarUrl:
                                'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                              name: 'Administrator',
                              username: 'root',
                              webUrl: 'http://127.0.0.1:3000/root',
                              __typename: 'UserCore',
                            },
                            userPermissions: {
                              adminNote: true,
                              awardEmoji: true,
                              readNote: true,
                              createNote: true,
                              resolveNote: true,
                              repositionNote: true,
                              __typename: 'NotePermissions',
                            },
                            __typename: 'Note',
                          },
                          {
                            id: 'gid://gitlab/DiscussionNote/235',
                            body: 'Thread comment',
                            bodyHtml: '<p data-sourcepos="1:1-1:15" dir="auto">Thread comment</p>',
                            system: false,
                            internal: false,
                            systemNoteIconName: null,
                            createdAt: '2023-01-18T09:09:54Z',
                            lastEditedAt: null,
                            url:
                              'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37?iid_path=true#note_191',
                            lastEditedBy: null,
                            discussion: {
                              id:
                                'gid://gitlab/Discussion/2bb1162fd0d39297d1a68fdd7d4083d3780af0f3',
                              __typename: 'Discussion',
                            },
                            author: {
                              id: 'gid://gitlab/User/1',
                              avatarUrl:
                                'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                              name: 'Administrator',
                              username: 'root',
                              webUrl: 'http://127.0.0.1:3000/root',
                              __typename: 'UserCore',
                            },
                            userPermissions: {
                              adminNote: true,
                              awardEmoji: true,
                              readNote: true,
                              createNote: true,
                              resolveNote: true,
                              repositionNote: true,
                              __typename: 'NotePermissions',
                            },
                            __typename: 'Note',
                          },
                        ],
                        __typename: 'NoteConnection',
                      },
                      __typename: 'Discussion',
                    },
                    {
                      id: 'gid://gitlab/Discussion/0f2f195ec0d1ef95ee9d5b10446b8e96a7d83864',
                      notes: {
                        nodes: [
                          {
                            id: 'gid://gitlab/WeightNote/0f2f195ec0d1ef95ee9d5b10446b8e96a9883864',
                            body: 'Main thread 2',
                            bodyHtml: '<p data-sourcepos="1:1-1:15" dir="auto">Main thread 2</p>',
                            systemNoteIconName: 'weight',
                            createdAt: '2022-11-25T07:16:20Z',
                            lastEditedAt: null,
                            url:
                              'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37?iid_path=true#note_191',
                            lastEditedBy: null,
                            system: false,
                            internal: false,
                            discussion: {
                              id:
                                'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da12723560987',
                            },
                            userPermissions: {
                              adminNote: false,
                              awardEmoji: true,
                              readNote: true,
                              createNote: true,
                              resolveNote: true,
                              repositionNote: true,
                              __typename: 'NotePermissions',
                            },
                            author: {
                              avatarUrl:
                                'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                              id: 'gid://gitlab/User/1',
                              name: 'Administrator',
                              username: 'root',
                              webUrl: 'http://127.0.0.1:3000/root',
                              __typename: 'UserCore',
                            },
                            __typename: 'Note',
                          },
                        ],
                        __typename: 'NoteConnection',
                      },
                      __typename: 'Discussion',
                    },
                  ],
                  __typename: 'DiscussionConnection',
                },
                __typename: 'WorkItemWidgetNotes',
              },
            ],
            __typename: 'WorkItem',
          },
        ],
      },
    },
  },
};

export const workItemNotesCreateSubscriptionResponse = {
  data: {
    workItemNoteCreated: {
      id: 'gid://gitlab/WeightNote/0f2f195ec0d1ef95ee9d5b10446b8e96a7d81864',
      body: 'changed weight to **89**',
      bodyHtml: '<p dir="auto">changed weight to <strong>89</strong></p>',
      systemNoteIconName: 'weight',
      createdAt: '2022-11-25T07:16:20Z',
      lastEditedAt: null,
      url: 'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37?iid_path=true#note_191',
      lastEditedBy: null,
      system: true,
      internal: false,
      discussion: {
        id: 'gid://gitlab/Discussion/8bbc4890b6ff0f2cde93a5a0947cd2b8a13d3b6e',
        notes: {
          nodes: [
            {
              id: 'gid://gitlab/WeightNote/0f2f195ec0d1ef95ee9d5b10446b8e96a9881864',
              body: 'changed weight to **89**',
              bodyHtml: '<p dir="auto">changed weight to <strong>89</strong></p>',
              systemNoteIconName: 'weight',
              createdAt: '2022-11-25T07:16:20Z',
              lastEditedAt: null,
              url: 'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37?iid_path=true#note_191',
              lastEditedBy: null,
              system: true,
              internal: false,
              discussion: {
                id: 'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da12723560987',
              },
              userPermissions: {
                adminNote: false,
                awardEmoji: true,
                readNote: true,
                createNote: true,
                resolveNote: true,
                repositionNote: true,
                __typename: 'NotePermissions',
              },
              author: {
                avatarUrl:
                  'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                id: 'gid://gitlab/User/1',
                name: 'Administrator',
                username: 'root',
                webUrl: 'http://127.0.0.1:3000/root',
                __typename: 'UserCore',
              },
              __typename: 'Note',
            },
          ],
        },
      },
      userPermissions: {
        adminNote: false,
        awardEmoji: true,
        readNote: true,
        createNote: true,
        resolveNote: true,
        repositionNote: true,
        __typename: 'NotePermissions',
      },
      author: {
        avatarUrl:
          'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
        id: 'gid://gitlab/User/1',
        name: 'Administrator',
        username: 'root',
        webUrl: 'http://127.0.0.1:3000/root',
        __typename: 'UserCore',
      },
      __typename: 'Note',
    },
  },
};

export const workItemNotesUpdateSubscriptionResponse = {
  data: {
    workItemNoteUpdated: {
      id: 'gid://gitlab/Note/0f2f195ec0d1ef95ee9d5b10446b8e96a9883894',
      body: 'changed title',
      bodyHtml: '<p dir="auto">changed title<strong>89</strong></p>',
      systemNoteIconName: 'pencil',
      createdAt: '2022-11-25T07:16:20Z',
      lastEditedAt: null,
      url: 'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37?iid_path=true#note_191',
      lastEditedBy: null,
      system: true,
      internal: false,
      discussion: {
        id: 'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da12723560987',
      },
      userPermissions: {
        adminNote: false,
        awardEmoji: true,
        readNote: true,
        createNote: true,
        resolveNote: true,
        repositionNote: true,
        __typename: 'NotePermissions',
      },
      author: {
        avatarUrl:
          'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
        id: 'gid://gitlab/User/1',
        name: 'Administrator',
        username: 'root',
        webUrl: 'http://127.0.0.1:3000/root',
        __typename: 'UserCore',
      },
      __typename: 'Note',
    },
  },
};

export const workItemNotesDeleteSubscriptionResponse = {
  data: {
    workItemNoteDeleted: {
      id: 'gid://gitlab/DiscussionNote/235',
      discussionId: 'gid://gitlab/Discussion/2bb1162fd0d39297d1a68fdd7d4083d3780af0f3',
      lastDiscussionNote: false,
    },
  },
};
