import { map } from 'lodash';
import { EMOJI_THUMBS_UP, EMOJI_THUMBS_DOWN } from '~/emoji/constants';
import {
  WIDGET_TYPE_LINKED_ITEMS,
  NEW_WORK_ITEM_IID,
  STATE_CLOSED,
  WIDGET_TYPE_CUSTOM_FIELDS,
  CUSTOM_FIELDS_TYPE_NUMBER,
} from '~/work_items/constants';

export const mockAssignees = [
  {
    __typename: 'UserCore',
    id: 'gid://gitlab/User/1',
    avatarUrl: '',
    webUrl: '',
    webPath: '/doe_I',
    name: 'John Doe',
    username: 'doe_I',
  },
  {
    __typename: 'UserCore',
    id: 'gid://gitlab/User/2',
    avatarUrl: '',
    webUrl: '',
    webPath: '/ruthfull',
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
  {
    __typename: 'Label',
    id: 'gid://gitlab/Label/3',
    title: 'Label 3',
    description: 'Label 3 description',
    color: '#fff',
    textColor: '#000',
  },
];

export const mockCrmContacts = [
  {
    __typename: 'CustomerRelationsContact',
    id: 'gid://gitlab/CustomerRelations::Contact/213',
    firstName: 'Jenee',
    lastName: "O'Reilly",
    email: "Jenee.O'Reilly-12@example.org",
    phone: null,
    description: null,
    active: true,
    organization: {
      __typename: 'CustomerRelationsOrganization',
      id: 'gid://gitlab/CustomerRelations::Organization/55',
      name: 'Anderson LLC-4',
      description: null,
      defaultRate: null,
    },
  },
  {
    __typename: 'CustomerRelationsContact',
    id: 'gid://gitlab/CustomerRelations::Contact/216',
    firstName: 'Kassie',
    lastName: 'Oberbrunner',
    email: 'Kassie.Oberbrunner-15@example.org',
    phone: null,
    description: null,
    active: true,
    organization: {
      __typename: 'CustomerRelationsOrganization',
      id: 'gid://gitlab/CustomerRelations::Organization/55',
      name: 'Anderson LLC-4',
      description: null,
      defaultRate: null,
    },
  },
  {
    __typename: 'CustomerRelationsContact',
    id: 'gid://gitlab/CustomerRelations::Contact/232',
    firstName: 'Liza',
    lastName: 'Osinski',
    email: 'Liza.Osinski-31@example.org',
    phone: null,
    description: null,
    active: true,
    organization: null,
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
  webPath: '123',
};

export const mockAwardEmojiThumbsUp = {
  name: EMOJI_THUMBS_UP,
  __typename: 'AwardEmoji',
  user: {
    id: 'gid://gitlab/User/5',
    name: 'Dave Smith',
    __typename: 'UserCore',
  },
};

export const mockAwardEmojiThumbsDown = {
  name: EMOJI_THUMBS_DOWN,
  __typename: 'AwardEmoji',
  user: {
    id: 'gid://gitlab/User/5',
    name: 'Dave Smith',
    __typename: 'UserCore',
  },
};

export const mockAwardsWidget = {
  nodes: [mockAwardEmojiThumbsUp, mockAwardEmojiThumbsDown],
  pageInfo: {
    hasNextPage: false,
    hasPreviousPage: false,
    startCursor: null,
    endCursor: null,
    __typename: 'PageInfo',
  },
  __typename: 'AwardEmojiConnection',
};

export const mockMoreThanDefaultAwardEmojisWidget = {
  nodes: [
    mockAwardEmojiThumbsUp,
    mockAwardEmojiThumbsDown,
    { ...mockAwardEmojiThumbsUp, name: 'one' },
    { ...mockAwardEmojiThumbsUp, name: 'two' },
    { ...mockAwardEmojiThumbsUp, name: 'three' },
    { ...mockAwardEmojiThumbsUp, name: 'four' },
    { ...mockAwardEmojiThumbsUp, name: 'five' },
    { ...mockAwardEmojiThumbsUp, name: 'six' },
    { ...mockAwardEmojiThumbsUp, name: 'seven' },
    { ...mockAwardEmojiThumbsUp, name: 'eight' },
    { ...mockAwardEmojiThumbsUp, name: 'nine' },
    { ...mockAwardEmojiThumbsUp, name: 'ten' },
  ],
  pageInfo: {
    hasNextPage: true,
    hasPreviousPage: false,
    startCursor: null,
    endCursor: 'endCursor',
    __typename: 'PageInfo',
  },
  __typename: 'AwardEmojiConnection',
};

export const workItemQueryResponse = {
  data: {
    workItem: {
      __typename: 'WorkItem',
      id: 'gid://gitlab/WorkItem/1',
      iid: '1',
      archived: false,
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
        webPath: '/root',
        __typename: 'UserCore',
      },
      project: {
        id: 'gid://gitlab/Project/7',
        __typename: 'Project',
      },
      namespace: {
        __typename: 'Project',
        id: '1',
        fullPath: 'test-project-path',
        name: 'Project name',
        fullName: 'Group name',
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
        adminParentLink: false,
        createNote: false,
        adminWorkItemLink: true,
        markNoteAsInternal: true,
        reportSpam: false,
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
          taskCompletionStatus: null,
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
                webUrl: '/gitlab-org/gitlab-test/-/work_items/4',
                reference: 'test-project-path#4',
                namespace: {
                  __typename: 'Project',
                  id: '1',
                  fullPath: 'test-project-path',
                  name: 'Project name',
                },
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
        archived: false,
        title: 'Updated title',
        state: 'OPEN',
        description: 'description',
        confidential: false,
        webUrl: 'http://gdk.test/gitlab-org/gitlab/-/issues/1',
        createdAt: '2022-08-03T12:41:54Z',
        updatedAt: '2022-08-08T12:41:54Z',
        closedAt: null,
        author: {
          ...mockAssignees[0],
        },
        project: {
          id: 'gid://gitlab/Project/7',
          __typename: 'Project',
        },
        namespace: {
          __typename: 'Project',
          id: '1',
          fullPath: 'test-project-path',
          name: 'Project name',
          fullName: 'Group name',
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
          adminParentLink: false,
          createNote: false,
          adminWorkItemLink: true,
          markNoteAsInternal: true,
          reportSpam: false,
          __typename: 'WorkItemPermissions',
        },
        reference: 'test-project-path#1',
        createNoteEmail:
          'gitlab-incoming+test-project-path-13fp7g6i9agekcv71s0jx9p58-issue-1@gmail.com',
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
                  webUrl: '/gitlab-org/gitlab-test/-/work_items/4',
                  reference: 'test-project-path#4',
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

export const mockworkItemReferenceQueryResponse = {
  data: {
    workItemsByReference: {
      nodes: [
        {
          id: 'gid://gitlab/WorkItem/705',
          iid: '111',
          title: 'Objective linked items 104',
          confidential: false,
          __typename: 'WorkItem',
        },
      ],
      __typename: 'WorkItemConnection',
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
        archived: false,
        title: 'Updated title',
        state: 'OPEN',
        description: 'description',
        webUrl: 'http://gdk.test/gitlab-org/gitlab/-/issues/1',
        confidential: false,
        createdAt: '2022-08-03T12:41:54Z',
        updatedAt: '2022-08-08T12:41:54Z',
        closedAt: null,
        author: {
          ...mockAssignees[0],
        },
        project: {
          id: 'gid://gitlab/Project/7',
          __typename: 'Project',
        },
        namespace: {
          __typename: 'Project',
          id: '1',
          fullPath: 'test-project-path',
          name: 'Project name',
          fullName: 'Group name',
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
          adminParentLink: false,
          createNote: false,
          adminWorkItemLink: true,
          markNoteAsInternal: true,
          reportSpam: false,
          __typename: 'WorkItemPermissions',
        },
        reference: 'gitlab-org/gitlab-test#1',
        createNoteEmail:
          'gitlab-incoming+gitlab-org-gitlab-test-2-ddpzuq0zd2wefzofcpcdr3dg7-issue-1@gmail.com',
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
                  webUrl: '/gitlab-org/gitlab-test/-/work_items/4',
                  reference: 'test-project-path#4',
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

export const mockParticipantWidget = {
  __typename: 'WorkItemWidgetParticipants',
  type: 'PARTICIPANTS',
  participants: {
    nodes: [
      {
        __typename: 'UserCore',
        id: 'gid://gitlab/User/5',
        avatarUrl: '/avatar2',
        name: 'rookie',
        username: 'rookie',
        webUrl: 'rookie',
        webPath: '/rookie',
      },
    ],
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

export const taskType = {
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

export const issueType = {
  __typename: 'WorkItemType',
  id: 'gid://gitlab/WorkItems::Type/2411',
  name: 'Issue',
  iconName: 'issue-type-issue',
};

export const epicType = {
  __typename: 'WorkItemType',
  id: 'gid://gitlab/WorkItems::Type/2411',
  name: 'Epic',
  iconName: 'issue-type-epic',
};

export const mockEmptyLinkedItems = {
  type: WIDGET_TYPE_LINKED_ITEMS,
  blocked: false,
  blockedByCount: 0,
  blockingCount: 0,
  linkedItems: {
    nodes: [],
    __typename: 'LinkedWorkItemTypeConnection',
  },
  __typename: 'WorkItemWidgetLinkedItems',
};

export const mockBlockingLinkedItem = {
  type: WIDGET_TYPE_LINKED_ITEMS,
  linkedItems: {
    nodes: [
      {
        linkId: 'gid://gitlab/WorkItems::RelatedWorkItemLink/8',
        linkType: 'blocks',
        workItemState: 'OPEN',
        workItem: {
          id: 'gid://gitlab/WorkItem/675',
          iid: '83',
          confidential: true,
          workItemType: {
            id: 'gid://gitlab/WorkItems::Type/5',
            name: 'Task',
            iconName: 'issue-type-task',
            __typename: 'WorkItemType',
          },
          namespace: {
            id: 'gid://gitlab/Group/1',
            fullPath: 'test-project-path',
            __typename: 'Namespace',
          },
          reference: 'test-project-path#1',
          title: 'Task 1201',
          state: 'OPEN',
          createdAt: '2023-03-28T10:50:16Z',
          closedAt: null,
          webUrl: '/gitlab-org/gitlab-test/-/work_items/83',
          widgets: [],
          __typename: 'WorkItem',
        },
        __typename: 'LinkedWorkItemType',
      },
    ],
    __typename: 'LinkedWorkItemTypeConnection',
  },
  __typename: 'WorkItemWidgetLinkedItems',
};

export const mockBlockedByLinkedItem = {
  type: WIDGET_TYPE_LINKED_ITEMS,
  linkedItems: {
    nodes: [
      {
        linkId: 'gid://gitlab/WorkItems::RelatedWorkItemLink/8',
        linkType: 'is_blocked_by',
        workItemState: 'OPEN',
        workItem: {
          id: 'gid://gitlab/WorkItem/675',
          iid: '83',
          confidential: true,
          workItemType: {
            id: 'gid://gitlab/WorkItems::Type/5',
            name: 'Task',
            iconName: 'issue-type-task',
            __typename: 'WorkItemType',
          },
          namespace: {
            id: 'gid://gitlab/Group/1',
            fullPath: 'test-project-path',
            __typename: 'Namespace',
          },
          reference: 'test-project-path#1',
          title: 'Task 1201',
          state: 'OPEN',
          createdAt: '2023-03-28T10:50:16Z',
          closedAt: null,
          webUrl: '/gitlab-org/gitlab-test/-/work_items/83',
          widgets: [],
          __typename: 'WorkItem',
        },
        __typename: 'LinkedWorkItemType',
      },
      {
        linkId: 'gid://gitlab/WorkItems::RelatedWorkItemLink/8',
        linkType: 'is_blocked_by',
        workItemState: 'OPEN',
        workItem: {
          id: 'gid://gitlab/WorkItem/676',
          iid: '84',
          confidential: true,
          workItemType: {
            id: 'gid://gitlab/WorkItems::Type/5',
            name: 'Task',
            iconName: 'issue-type-task',
            __typename: 'WorkItemType',
          },
          namespace: {
            id: 'gid://gitlab/Group/1',
            fullPath: 'test-project-path',
            __typename: 'Namespace',
          },
          reference: 'test-project-path#1',
          title: 'Task 1202',
          state: 'OPEN',
          createdAt: '2023-03-28T10:50:16Z',
          closedAt: null,
          webUrl: '/gitlab-org/gitlab-test/-/work_items/84',
          widgets: [],
          __typename: 'WorkItem',
        },
        __typename: 'LinkedWorkItemType',
      },
    ],
    __typename: 'LinkedWorkItemTypeConnection',
  },
  __typename: 'WorkItemWidgetLinkedItems',
};

export const mockNoLinkedItems = {
  type: WIDGET_TYPE_LINKED_ITEMS,
  linkedItems: {
    nodes: [],
  },
};

export const mockLinkedItems = {
  type: WIDGET_TYPE_LINKED_ITEMS,
  linkedItems: {
    nodes: [
      {
        linkId: 'gid://gitlab/WorkItems::RelatedWorkItemLink/8',
        linkType: 'relates_to',
        workItemState: 'OPEN',
        workItem: {
          id: 'gid://gitlab/WorkItem/675',
          iid: '83',
          confidential: true,
          workItemType: {
            id: 'gid://gitlab/WorkItems::Type/5',
            name: 'Task',
            iconName: 'issue-type-task',
            __typename: 'WorkItemType',
          },
          namespace: {
            id: 'gid://gitlab/Group/1',
            fullPath: 'test-project-path',
            __typename: 'Namespace',
          },
          reference: 'test-project-path#83',
          title: 'Task 1201',
          state: 'OPEN',
          createdAt: '2023-03-28T10:50:16Z',
          closedAt: null,
          webUrl: '/gitlab-org/gitlab-test/-/work_items/83',
          widgets: [],
          __typename: 'WorkItem',
        },
        __typename: 'LinkedWorkItemType',
      },
      {
        linkId: 'gid://gitlab/WorkItems::RelatedWorkItemLink/9',
        linkType: 'is_blocked_by',
        workItemState: 'OPEN',
        workItem: {
          id: 'gid://gitlab/WorkItem/646',
          iid: '55',
          confidential: true,
          workItemType: {
            id: 'gid://gitlab/WorkItems::Type/6',
            name: 'Objective',
            iconName: 'issue-type-objective',
            __typename: 'WorkItemType',
          },
          namespace: {
            id: 'gid://gitlab/Group/2',
            fullPath: 'test-project-path',
            __typename: 'Namespace',
          },
          reference: 'test-project-path#55',
          title: 'Multilevel Objective 1',
          state: 'OPEN',
          createdAt: '2023-03-28T10:50:16Z',
          closedAt: null,
          webUrl: '/gitlab-org/gitlab-test/-/work_items/55',
          widgets: [],
          __typename: 'WorkItem',
        },
        __typename: 'LinkedWorkItemType',
      },
      {
        linkId: 'gid://gitlab/WorkItems::RelatedWorkItemLink/10',
        linkType: 'blocks',
        workItemState: 'OPEN',
        workItem: {
          id: 'gid://gitlab/WorkItem/647',
          iid: '56',
          confidential: true,
          workItemType: {
            id: 'gid://gitlab/WorkItems::Type/6',
            name: 'Objective',
            iconName: 'issue-type-objective',
            __typename: 'WorkItemType',
          },
          namespace: {
            id: 'gid://gitlab/Group/3',
            fullPath: 'test-project-path',
            __typename: 'Namespace',
          },
          reference: 'test-project-path#56',
          title: 'Multilevel Objective 2',
          state: 'OPEN',
          createdAt: '2023-03-28T10:50:16Z',
          closedAt: null,
          webUrl: '/gitlab-org/gitlab-test/-/work_items/56',
          widgets: [],
          __typename: 'WorkItem',
        },
        __typename: 'LinkedWorkItemType',
      },
    ],
    __typename: 'LinkedWorkItemTypeConnection',
  },
  __typename: 'WorkItemWidgetLinkedItems',
};

export const workItemLinkedItemsResponse = {
  data: {
    workspace: {
      __typename: 'Namespace',
      id: 'gid://gitlab/Group/1',
      workItem: {
        id: 'gid://gitlab/WorkItem/2',
        widgets: [mockLinkedItems],
        __typename: 'WorkItem',
      },
    },
  },
};

export const workItemEmptyLinkedItemsResponse = {
  data: {
    workspace: {
      __typename: 'Namespace',
      id: 'gid://gitlab/Group/1',
      workItem: {
        id: 'gid://gitlab/WorkItem/2',
        widgets: [
          {
            type: WIDGET_TYPE_LINKED_ITEMS,
            linkedItems: {
              nodes: [],
              __typename: 'LinkedWorkItemTypeConnection',
            },
            __typename: 'WorkItemWidgetLinkedItems',
          },
        ],
        __typename: 'WorkItem',
      },
    },
  },
};

export const workItemSingleLinkedItemResponse = {
  data: {
    workspace: {
      __typename: 'Namespace',
      id: 'gid://gitlab/Group/1',
      workItem: {
        id: 'gid://gitlab/WorkItem/2',
        widgets: [
          {
            type: WIDGET_TYPE_LINKED_ITEMS,
            linkedItems: {
              nodes: [
                {
                  linkId: 'gid://gitlab/WorkItems::RelatedWorkItemLink/8',
                  linkType: 'is_blocked_by',
                  workItemState: 'OPEN',
                  workItem: {
                    id: 'gid://gitlab/WorkItem/675',
                    iid: '83',
                    confidential: true,
                    workItemType: {
                      id: 'gid://gitlab/WorkItems::Type/5',
                      name: 'Task',
                      iconName: 'issue-type-task',
                      __typename: 'WorkItemType',
                    },
                    namespace: {
                      id: 'gid://gitlab/Group/1',
                      fullPath: 'test-project-path',
                      __typename: 'Namespace',
                    },
                    reference: 'test-project-path#1',
                    title: 'Task 1201',
                    state: 'OPEN',
                    createdAt: '2023-03-28T10:50:16Z',
                    closedAt: null,
                    webUrl: '/gitlab-org/gitlab-test/-/work_items/83',
                    widgets: [],
                    __typename: 'WorkItem',
                  },
                  __typename: 'LinkedWorkItemType',
                },
              ],
              __typename: 'LinkedWorkItemTypeConnection',
            },
            __typename: 'WorkItemWidgetLinkedItems',
          },
        ],
        __typename: 'WorkItem',
      },
    },
  },
};

export const workItemNoBlockedByLinkedItemsResponse = {
  data: {
    workspace: {
      __typename: 'Namespace',
      id: 'gid://gitlab/Group/1',
      workItem: {
        id: 'gid://gitlab/WorkItem/2',
        widgets: [mockNoLinkedItems],
        __typename: 'WorkItem',
      },
    },
  },
};

export const workItemBlockedByLinkedItemsResponse = {
  data: {
    workspace: {
      __typename: 'Namespace',
      id: 'gid://gitlab/Group/1',
      workItem: {
        id: 'gid://gitlab/WorkItem/2',
        widgets: [mockBlockedByLinkedItem],
        __typename: 'WorkItem',
      },
    },
  },
};

export const workItemDevelopmentMRNodes = [
  {
    id: 'gid://gitlab/MergeRequestsClosingIssues/61',
    fromMrDescription: true,
    mergeRequest: {
      iid: '13',
      id: 'gid://gitlab/MergeRequest/121',
      title: 'Karma configuration',
      webUrl: 'http://127.0.0.1:3000/flightjs/Flight/-/merge_requests/13',
      state: 'opened',
      sourceBranch: '13-branch',
      reference: '!11',
      headPipeline: null,
      milestone: null,
      project: {
        name: 'Flight',
        id: 'gid://gitlab/Project/1',
        namespace: {
          path: 'flightjs',
          __typename: 'Namespace',
        },
        __typename: 'Project',
      },
      assignees: {
        nodes: [
          {
            webUrl: 'http://127.0.0.1:3000/root',
            id: 'gid://gitlab/User/1',
            name: 'Administrator',
            webPath: '/root',
            avatarUrl:
              'https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon',
            __typename: 'MergeRequestAssignee',
          },
        ],
        __typename: 'MergeRequestAssigneeConnection',
      },
      __typename: 'MergeRequest',
    },
    __typename: 'WorkItemClosingMergeRequest',
  },
  {
    id: 'gid://gitlab/MergeRequestsClosingIssues/62',
    fromMrDescription: true,
    mergeRequest: {
      iid: '15',
      id: 'gid://gitlab/MergeRequest/123',
      title: 'got immutability working end to end.  Scope for some cleanup/optimization',
      webUrl: 'http://127.0.0.1:3000/flightjs/Flight/-/merge_requests/15',
      state: 'merged',
      sourceBranch: '13-branch',
      reference: '!11',
      headPipeline: null,
      milestone: null,
      project: {
        id: 'gid://gitlab/Project/1',
        name: 'Flight',
        namespace: {
          path: 'flightjs',
          __typename: 'Namespace',
        },
        __typename: 'Project',
      },
      assignees: {
        nodes: [],
        __typename: 'MergeRequestAssigneeConnection',
      },
      __typename: 'MergeRequest',
    },
    __typename: 'WorkItemClosingMergeRequest',
  },
  {
    id: 'gid://gitlab/MergeRequestsClosingIssues/63',
    fromMrDescription: true,
    mergeRequest: {
      iid: '14',
      id: 'gid://gitlab/MergeRequest/122',
      title: "Draft: Always call registry's trigger method from withRegistration",
      webUrl: 'http://127.0.0.1:3000/flightjs/Flight/-/merge_requests/14',
      state: 'closed',
      sourceBranch: '13-branch',
      reference: '!11',
      headPipeline: null,
      milestone: null,
      project: {
        id: 'gid://gitlab/Project/1',
        name: 'Flight',
        namespace: {
          path: 'flightjs',
          __typename: 'Namespace',
        },
        __typename: 'Project',
      },
      assignees: {
        nodes: [],
        __typename: 'MergeRequestAssigneeConnection',
      },
      __typename: 'MergeRequest',
    },
    __typename: 'WorkItemClosingMergeRequest',
  },
  {
    id: 'gid://gitlab/MergeRequestsClosingIssues/64',
    fromMrDescription: true,
    mergeRequest: {
      iid: '12',
      id: 'gid://gitlab/MergeRequest/120',
      title: 'got immutability working and other changes and end to end',
      webUrl: 'http://127.0.0.1:3000/flightjs/Flight/-/merge_requests/12',
      state: 'closed',
      sourceBranch: '13-branch',
      reference: '!11',
      headPipeline: null,
      milestone: null,
      project: {
        id: 'gid://gitlab/Project/1',
        name: 'Flight',
        namespace: {
          path: 'flightjs',
          __typename: 'Namespace',
        },
        __typename: 'Project',
      },
      assignees: {
        nodes: [
          {
            webUrl: 'http://127.0.0.1:3000/root',
            id: 'gid://gitlab/User/1',
            name: 'Administrator',
            webPath: '/root',
            avatarUrl:
              'https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon',
            __typename: 'MergeRequestAssignee',
          },
        ],
        __typename: 'MergeRequestAssigneeConnection',
      },
      __typename: 'MergeRequest',
    },
    __typename: 'WorkItemClosingMergeRequest',
  },
  {
    id: 'gid://gitlab/MergeRequestsClosingIssues/65',
    fromMrDescription: true,
    mergeRequest: {
      iid: '11',
      id: 'gid://gitlab/MergeRequest/119',
      title: '[UX] Work items: Development widget (MRs, branches, feature flags)',
      webUrl: 'http://127.0.0.1:3000/flightjs/Flight/-/merge_requests/11',
      state: 'opened',
      sourceBranch: '13-branch',
      reference: '!11',
      headPipeline: null,
      milestone: null,
      project: {
        id: 'gid://gitlab/Project/1',
        name: 'Flight',
        namespace: {
          path: 'flightjs',
          __typename: 'Namespace',
        },
        __typename: 'Project',
      },
      assignees: {
        nodes: [
          {
            webUrl: 'http://127.0.0.1:3000/contributor_001',
            id: 'gid://gitlab/User/50',
            name: 'Contributor',
            webPath: '/contributor_001',
            avatarUrl:
              'https://www.gravatar.com/avatar/0425546bf992b09bf77c16afe53f3824a919c5f4a5ef3355d493155740dfaaf5?s=80&d=identicon',
            __typename: 'MergeRequestAssignee',
          },
          {
            webUrl: 'http://127.0.0.1:3000/reported_user_17',
            id: 'gid://gitlab/User/40',
            name: "Amira O'Keefe",
            webPath: '/reported_user_17',
            avatarUrl:
              'https://www.gravatar.com/avatar/4650f7f452b5606f219ac12ed4c2869705752e62b94e28d3263aa9a5598c6ab8?s=80&d=identicon',
            __typename: 'MergeRequestAssignee',
          },
          {
            webUrl: 'http://127.0.0.1:3000/reported_user_5',
            id: 'gid://gitlab/User/28',
            name: 'Echo Littel',
            webPath: '/reported_user_5',
            avatarUrl:
              'https://www.gravatar.com/avatar/3dcc93993fcf6705adb708f460d314d0994463ec2cb0a693e1e0597111acd3c7?s=80&d=identicon',
            __typename: 'MergeRequestAssignee',
          },
          {
            webUrl: 'http://127.0.0.1:3000/root',
            id: 'gid://gitlab/User/1',
            name: 'Administrator',
            webPath: '/root',
            avatarUrl:
              'https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon',
            __typename: 'MergeRequestAssignee',
          },
        ],
        __typename: 'MergeRequestAssigneeConnection',
      },
      __typename: 'MergeRequest',
    },
    __typename: 'WorkItemClosingMergeRequest',
  },
];

export const workItemDevelopmentFeatureFlagNodes = [
  {
    active: true,
    id: 'gid://gitlab/Operations::FeatureFlag/1',
    name: 'flag1',
    path: 'http://127.0.0.1:3000/flightjs/Flight/-/feature_flags/1/edit',
    reference: '[feature_flag:1]',
    __typename: 'FeatureFlag',
  },
  {
    active: false,
    id: 'gid://gitlab/Operations::FeatureFlag/2',
    name: 'flag2',
    path: 'http://127.0.0.1:3000/flightjs/Flight/-/feature_flags/2/edit',
    reference: '[feature_flag:2]',
    __typename: 'FeatureFlag',
  },
  {
    active: false,
    id: 'gid://gitlab/Operations::FeatureFlag/3',
    name: 'flag3',
    path: 'http://127.0.0.1:3000/flightjs/Flight/-/feature_flags/3/edit',
    reference: '[feature_flag:3]',
    __typename: 'FeatureFlag',
  },
];

export const workItemRelatedBranchNodes = [
  {
    name: '178-issue',
    comparePath: '/flightjs/Flight/-/compare/master...178-issue',
    __typename: 'WorkItemRelatedBranch',
  },
  {
    name: '178-issue-10',
    comparePath: '/flightjs/Flight/-/compare/master...178-issue-10',
    __typename: 'WorkItemRelatedBranch',
  },
];

export const workItemDevelopmentFragmentResponse = ({
  mrNodes = workItemDevelopmentMRNodes,
  willAutoCloseByMergeRequest = false,
  featureFlagNodes = workItemDevelopmentFeatureFlagNodes,
  branchNodes = workItemRelatedBranchNodes,
  relatedMergeRequests = map(workItemDevelopmentMRNodes, 'mergeRequest'),
} = {}) => {
  return {
    type: 'DEVELOPMENT',
    willAutoCloseByMergeRequest,
    relatedMergeRequests: {
      nodes: relatedMergeRequests,
      __typename: 'MergeRequestConnection',
    },
    featureFlags: {
      nodes: featureFlagNodes,
      __typename: 'FeatureFlagConnection',
    },
    relatedBranches: {
      nodes: branchNodes,
      __typename: 'WorkItemRelatedBranchConnection',
    },
    closingMergeRequests: {
      nodes: mrNodes,
      __typename: 'WorkItemClosingMergeRequestConnection',
    },
    __typename: 'WorkItemWidgetDevelopment',
  };
};

export const workItemDevelopmentResponse = ({
  iid = '1',
  id = 'gid://gitlab/WorkItem/1',
  developmentItems,
} = {}) => ({
  data: {
    workItem: {
      __typename: 'WorkItem',
      id,
      iid,
      namespace: {
        __typename: 'Project',
        id: '1',
      },
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
          ...developmentItems,
        },
      ],
    },
  },
});

export const mockRolledUpCountsByType = [
  {
    countsByState: {
      opened: 0,
      all: 3,
      closed: 0,
      __typename: 'WorkItemStateCountsType',
    },
    workItemType: {
      id: 'gid://gitlab/WorkItems::Type/8',
      name: 'Epic',
      iconName: 'issue-type-epic',
      __typename: 'WorkItemType',
    },
    __typename: 'WorkItemTypeCountsByState',
  },
  {
    countsByState: {
      opened: 0,
      all: 5,
      closed: 2,
      __typename: 'WorkItemStateCountsType',
    },
    workItemType: {
      id: 'gid://gitlab/WorkItems::Type/1',
      name: 'Issue',
      iconName: 'issue-type-issue',
      __typename: 'WorkItemType',
    },
    __typename: 'WorkItemTypeCountsByState',
  },
  {
    countsByState: {
      opened: 0,
      all: 2,
      closed: 1,
      __typename: 'WorkItemStateCountsType',
    },
    workItemType: {
      id: 'gid://gitlab/WorkItems::Type/5',
      name: 'Task',
      iconName: 'issue-type-task',
      __typename: 'WorkItemType',
    },
    __typename: 'WorkItemTypeCountsByState',
  },
];

export const workItemResponseFactory = ({
  iid = '1',
  id = 'gid://gitlab/WorkItem/1',
  canUpdate = false,
  canDelete = false,
  canCreateNote = false,
  adminParentLink = false,
  reportSpam = false,
  canAdminWorkItemLink = true,
  canMarkNoteAsInternal = true,
  notificationsWidgetPresent = true,
  currentUserTodosWidgetPresent = true,
  awardEmojiWidgetPresent = true,
  subscribed = true,
  allowsMultipleAssignees = true,
  assigneesWidgetPresent = true,
  datesWidgetPresent = true,
  weightWidgetPresent = true,
  timeTrackingWidgetPresent = true,
  participantsWidgetPresent = true,
  progressWidgetPresent = true,
  milestoneWidgetPresent = true,
  iterationWidgetPresent = true,
  healthStatusWidgetPresent = true,
  notesWidgetPresent = true,
  designWidgetPresent = true,
  customFieldsWidgetPresent = true,
  confidential = false,
  hasChildren = true,
  discussionLocked = false,
  canInviteMembers = false,
  labelsWidgetPresent = true,
  hierarchyWidgetPresent = true,
  linkedItemsWidgetPresent = true,
  crmContactsWidgetPresent = true,
  emailParticipantsWidgetPresent = true,
  colorWidgetPresent = true,
  labels = mockLabels,
  crmContacts = mockCrmContacts,
  allowsScopedLabels = false,
  lastEditedAt = null,
  lastEditedBy = null,
  taskCompletionStatus = null,
  withCheckboxes = false,
  parent = mockParent.parent,
  workItemType = taskType,
  author = mockAssignees[0],
  createdAt = '2022-08-03T12:41:54Z',
  updatedAt = '2022-08-08T12:32:54Z',
  awardEmoji = mockAwardsWidget,
  state = 'OPEN',
  linkedItems = mockEmptyLinkedItems,
  color = '#1068bf',
  editableWeightWidget = true,
  hasParent = false,
  healthStatus = 'onTrack',
  rolledUpHealthStatus = [],
  weight = null,
  rolledUpWeight = 0,
  rolledUpCompletedWeight = 0,
  descriptionText = 'some **great** text',
  descriptionHtml = '<p data-sourcepos="1:1-1:19" dir="auto">some <strong>great</strong> text</p>',
  developmentWidgetPresent = false,
} = {}) => ({
  data: {
    workItem: {
      __typename: 'WorkItem',
      id,
      iid,
      archived: false,
      title: 'Updated title',
      state,
      description: descriptionText,
      webUrl: 'http://gdk.test/gitlab-org/gitlab/-/issues/1',
      confidential,
      createdAt,
      updatedAt,
      closedAt: null,
      author,
      project: {
        id: 'gid://gitlab/Project/7',
        __typename: 'Project',
      },
      namespace: {
        __typename: 'Project',
        id: '1',
        fullPath: 'test-project-path',
        name: 'Project name',
        fullName: 'Group name',
      },
      workItemType,
      userPermissions: {
        deleteWorkItem: canDelete,
        updateWorkItem: canUpdate,
        setWorkItemMetadata: canUpdate,
        adminParentLink,
        adminWorkItemLink: canAdminWorkItemLink,
        createNote: canCreateNote,
        markNoteAsInternal: canMarkNoteAsInternal,
        reportSpam,
        __typename: 'WorkItemPermissions',
      },
      reference: 'test-project-path#1',
      createNoteEmail:
        'gitlab-incoming+test-project-path-13fp7g6i9agekcv71s0jx9p58-issue-1@gmail.com',
      ...(customFieldsWidgetPresent
        ? {
            mockWidgets: [
              {
                __typename: 'LocalWorkItemCustomFields',
                type: WIDGET_TYPE_CUSTOM_FIELDS,
                customFieldValues: [
                  {
                    id: 'gid://gitlab/CustomFieldValue/1',
                    customField: {
                      id: '1-number',
                      fieldType: CUSTOM_FIELDS_TYPE_NUMBER,
                      name: 'Number custom field label',
                      __typename: 'LocalWorkItemCustomField',
                    },
                    value: 5,
                    __typename: 'LocalWorkItemNumberFieldValue',
                  },
                ],
              },
            ],
          }
        : {}),
      widgets: [
        {
          __typename: 'WorkItemWidgetDescription',
          type: 'DESCRIPTION',
          description: withCheckboxes ? descriptionTextWithCheckboxes : descriptionText,
          descriptionHtml: withCheckboxes ? descriptionHtmlWithCheckboxes : descriptionHtml,
          lastEditedAt,
          lastEditedBy,
          taskCompletionStatus,
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
              isFixed: false,
              rollUp: true,
            }
          : { type: 'MOCK TYPE' },
        weightWidgetPresent
          ? {
              type: 'WEIGHT',
              weight,
              rolledUpWeight,
              rolledUpCompletedWeight,
              widgetDefinition: {
                editable: editableWeightWidget,
                rollUp: !editableWeightWidget,
                __typename: 'WorkItemWidgetDefinitionWeight',
              },
              __typename: 'WorkItemWidgetWeight',
            }
          : { type: 'MOCK TYPE' },
        iterationWidgetPresent
          ? {
              __typename: 'WorkItemWidgetIteration',
              type: 'ITERATION',
              iteration: {
                id: 'gid://gitlab/Iteration/1215',
                title: 'Iteration default title',
                startDate: '2022-09-22',
                dueDate: '2022-09-30',
                webUrl: 'http://127.0.0.1:3000/groups/flightjs/-/iterations/23205',
                iterationCadence: {
                  id: 'gid://gitlab/Iterations::Cadence/5852',
                  title: 'A dolores assumenda harum non facilis similique delectus quod.',
                  __typename: 'IterationCadence',
                },
              },
            }
          : { type: 'MOCK TYPE' },
        timeTrackingWidgetPresent
          ? {
              __typename: 'WorkItemWidgetTimeTracking',
              type: 'TIME_TRACKING',
              timeEstimate: 5,
              timelogs: {
                nodes: [
                  {
                    __typename: 'WorkItemTimelog',
                    id: 'gid://gitlab/WorkItemTimelog/18',
                    timeSpent: 14400,
                    user: {
                      id: 'user-1',
                      name: 'John Doe18',
                      __typename: 'UserCore',
                    },
                    spentAt: '2020-05-01T00:00:00Z',
                    note: {
                      id: 'note-1',
                      body: 'A note',
                      __typename: 'Note',
                    },
                    summary: 'A summary',
                    userPermissions: {
                      adminTimelog: true,
                      __typename: 'TimelogPermissions',
                    },
                  },
                ],
                __typename: 'WorkItemTimelogConnection',
              },
              totalTimeSpent: 3,
            }
          : { type: 'MOCK TYPE' },
        participantsWidgetPresent
          ? {
              __typename: 'WorkItemWidgetParticipants',
              type: 'PARTICIPANTS',
              participants: {
                nodes: [
                  {
                    __typename: 'UserCore',
                    id: 'gid://gitlab/User/5',
                    avatarUrl: '/avatar2',
                    name: 'rookie',
                    username: 'rookie',
                    webUrl: 'rookie',
                    webPath: '/rookie',
                  },
                ],
              },
            }
          : { type: 'MOCK TYPE' },
        progressWidgetPresent
          ? {
              __typename: 'WorkItemWidgetProgress',
              type: 'PROGRESS',
              progress: 0,
              updatedAt: new Date(),
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
              rolledUpHealthStatus,
              healthStatus,
            }
          : { type: 'MOCK TYPE' },
        notesWidgetPresent
          ? {
              __typename: 'WorkItemWidgetNotes',
              type: 'NOTES',
              discussionLocked,
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
        hierarchyWidgetPresent
          ? {
              __typename: 'WorkItemWidgetHierarchy',
              type: 'HIERARCHY',
              hasChildren,
              rolledUpCountsByType: mockRolledUpCountsByType,
              hasParent,
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
                    webUrl: '/gitlab-org/gitlab-test/-/work_items/5',
                    reference: 'test-project-path#5',
                    namespace: {
                      __typename: 'Project',
                      id: '1',
                      fullPath: 'test-project-path',
                      name: 'Project name',
                    },
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
            }
          : { type: 'MOCK TYPE' },
        notesWidgetPresent
          ? {
              __typename: 'WorkItemWidgetNotes',
              type: 'NOTES',
              discussionLocked,
            }
          : { type: 'MOCK TYPE' },
        notificationsWidgetPresent
          ? {
              __typename: 'WorkItemWidgetNotifications',
              type: 'NOTIFICATIONS',
              subscribed,
            }
          : { type: 'MOCK TYPE' },
        currentUserTodosWidgetPresent
          ? {
              type: 'CURRENT_USER_TODOS',
              currentUserTodos: {
                nodes: [
                  {
                    id: 'gid://gitlab/Todo/1',
                    __typename: 'Todo',
                  },
                ],
                __typename: 'TodoConnection',
              },
              __typename: 'WorkItemWidgetCurrentUserTodos',
            }
          : { type: 'MOCK TYPE' },
        awardEmojiWidgetPresent
          ? {
              __typename: 'WorkItemWidgetAwardEmoji',
              type: 'AWARD_EMOJI',
              awardEmoji,
            }
          : { type: 'MOCK TYPE' },
        linkedItemsWidgetPresent ? linkedItems : { type: 'MOCK TYPE' },
        colorWidgetPresent
          ? {
              color,
              textColor: '#FFFFFF',
              type: 'COLOR',
              __typename: 'WorkItemWidgetColor',
            }
          : { type: 'MOCK TYPE' },
        designWidgetPresent
          ? {
              __typename: 'WorkItemWidgetDesigns',
              type: 'DESIGNS',
            }
          : { type: 'MOCK TYPE' },
        crmContactsWidgetPresent
          ? {
              __typename: 'WorkItemWidgetCrmContacts',
              type: 'CRM_CONTACTS',
              contacts: {
                nodes: crmContacts,
                __typename: 'CustomerRelationsContactConnection',
              },
            }
          : {
              type: 'MOCK TYPE',
            },
        emailParticipantsWidgetPresent
          ? {
              __typename: 'WorkItemWidgetEmailParticipants',
              type: 'EMAIL_PARTICIPANTS',
            }
          : { type: 'MOCK TYPE' },
        developmentWidgetPresent
          ? {
              type: 'DEVELOPMENT',
              __typename: 'WorkItemWidgetDevelopment',
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
        workItem: response.data.workItem,
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

export const createWorkItemMutationResponse = {
  data: {
    workItemCreate: {
      __typename: 'WorkItemCreatePayload',
      workItem: {
        __typename: 'WorkItem',
        id: 'gid://gitlab/WorkItem/1',
        iid: '1',
        archived: false,
        title: 'Updated title',
        state: 'OPEN',
        description: 'description',
        confidential: false,
        createdAt: '2022-08-03T12:41:54Z',
        closedAt: null,
        webUrl: 'http://gdk.test/gitlab-org/gitlab/-/issues/1',
        author: {
          ...mockAssignees[0],
        },
        project: {
          id: 'gid://gitlab/Project/7',
          __typename: 'Project',
        },
        namespace: {
          __typename: 'Project',
          id: '1',
          fullPath: 'test-project-path',
          name: 'Project name',
          fullName: 'Group name',
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
          adminParentLink: false,
          createNote: false,
          adminWorkItemLink: true,
          markNoteAsInternal: true,
          reportSpam: false,
          __typename: 'WorkItemPermissions',
        },
        reference: 'test-project-path#1',
        createNoteEmail:
          'gitlab-incoming+test-project-path-13fp7g6i9agekcv71s0jx9p58-issue-1@gmail.com',
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

export const workItemHierarchyNoUpdatePermissionResponse = {
  data: {
    workItem: {
      id: 'gid://gitlab/WorkItem/1',
      iid: '1',
      archived: false,
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
        adminParentLink: false,
        createNote: false,
        adminWorkItemLink: true,
        markNoteAsInternal: true,
        reportSpam: false,
        __typename: 'WorkItemPermissions',
      },
      namespace: {
        __typename: 'Project',
        id: '1',
        fullPath: 'test-project-path',
        name: 'Project name',
        fullName: 'Project name',
      },
      confidential: false,
      reference: 'test-project-path#1',
      widgets: [
        {
          type: 'HIERARCHY',
          parent: null,
          hasChildren: true,
          hasParent: false,
          depthLimitReachedByType: [],
          rolledUpCountsByType: [],
          children: {
            pageInfo: {
              hasNextPage: false,
              hasPreviousPage: false,
              startCursor: null,
              endCursor: null,
              __typename: 'PageInfo',
            },
            count: 1,
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
                reference: 'test-project-path#2',
                state: 'OPEN',
                confidential: false,
                createdAt: '2022-08-03T12:41:54Z',
                namespace: {
                  __typename: 'Project',
                  id: '1',
                  fullPath: 'test-project-path',
                  name: 'Project name',
                  fullName: 'Project name',
                },
                closedAt: null,
                webUrl: '/gitlab-org/gitlab-test/-/work_items/2',
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
  LINKED_ITEMS: {
    type: WIDGET_TYPE_LINKED_ITEMS,
    __typename: 'WorkItemWidgetLinkedItems',
    ...mockLinkedItems,
  },
  HIERARCHY: {
    type: 'HIERARCHY',
    hasChildren: false,
    rolledUpCountsByType: [],
    __typename: 'WorkItemWidgetHierarchy',
  },
};

export const workItemChangeTypeWidgets = {
  MILESTONE: {
    type: 'MILESTONE',
    __typename: 'WorkItemWidgetMilestone',
    milestone: mockMilestone,
  },
  ITERATION: {
    type: 'ITERATION',
    iteration: {
      id: 'gid://gitlab/Iteration/86312',
      __typename: 'Iteration',
    },
    __typename: 'WorkItemWidgetIteration',
  },
  DEVELOPMENT: {
    type: 'DEVELOPMENT',
    relatedBranches: {
      nodes: [
        {
          id: '1',
        },
      ],
      __typename: 'WorkItemRelatedBranchConnection',
    },
  },
  WEIGHT: {
    type: 'WEIGHT',
    weight: 1,
    __typename: 'WorkItemWidgetWeight',
  },
  CRM_CONTACTS: {
    type: 'CRM_CONTACTS',
    contacts: {
      nodes: [
        {
          id: 'gid://gitlab/CustomerRelations::Contact/50',
          __typename: 'CustomerRelationsContact',
        },
      ],
      __typename: 'CustomerRelationsContactConnection',
    },
    __typename: 'WorkItemWidgetCrmContacts',
  },
  TIME_TRACKING: {
    type: 'TIME_TRACKING',
    timeEstimate: 10,
    timelogs: {
      nodes: [
        {
          __typename: 'WorkItemTimelog',
          id: 'gid://gitlab/Timelog/2',
        },
      ],
      __typename: 'WorkItemTimelogConnection',
    },
    totalTimeSpent: 10800,
    __typename: 'WorkItemWidgetTimeTracking',
  },
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
  reference: 'test-project-path#2',
  namespace: {
    __typename: 'Project',
    id: '1',
    fullPath: 'test-project-path',
    name: 'Project name',
  },
  createdAt: '2022-08-03T12:41:54Z',
  closedAt: null,
  webUrl: '/gitlab-org/gitlab-test/-/work_items/2',
  widgets: [workItemObjectiveMetadataWidgets.LINKED_ITEMS],
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
  reference: 'test-project-path#3',
  namespace: {
    __typename: 'Project',
    id: '1',
    fullPath: 'test-project-path',
    name: 'Project name',
  },
  createdAt: '2022-08-03T12:41:54Z',
  closedAt: '2022-08-12T13:07:52Z',
  webUrl: '/gitlab-org/gitlab-test/-/work_items/3',
  widgets: [workItemObjectiveMetadataWidgets.LINKED_ITEMS],
  __typename: 'WorkItem',
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
  reference: 'test-project-path#4',
  namespace: {
    __typename: 'Project',
    id: '1',
    fullPath: 'test-project-path',
    name: 'Project name',
  },
  createdAt: '2022-08-03T12:41:54Z',
  closedAt: null,
  webUrl: '/gitlab-org/gitlab-test/-/work_items/4',
  widgets: [
    workItemObjectiveMetadataWidgets.ASSIGNEES,
    workItemObjectiveMetadataWidgets.LINKED_ITEMS,
    workItemObjectiveMetadataWidgets.MILESTONE,
    {
      type: 'HIERARCHY',
      hasChildren: false,
      rolledUpCountsByType: [],
      __typename: 'WorkItemWidgetHierarchy',
    },
  ],
  __typename: 'WorkItem',
};

export const workItemEpic = {
  id: 'gid://gitlab/WorkItem/4',
  iid: '4',
  workItemType: {
    id: 'gid://gitlab/WorkItems::Type/6',
    name: 'Epic',
    iconName: 'issue-type-epic',
    __typename: 'WorkItemType',
  },
  title: 'bar',
  state: 'OPEN',
  confidential: false,
  reference: 'test-project-path#4',
  namespace: {
    __typename: 'Project',
    id: '1',
    fullPath: 'gitlab-org/gitlab-test',
    name: 'Project name',
  },
  createdAt: '2022-08-03T12:41:54Z',
  closedAt: null,
  webUrl: 'http://127.0.0.1:3000/groups/gitlab-org/gitlab-test/-/work_items/4',
  widgets: [
    workItemObjectiveMetadataWidgets.ASSIGNEES,
    workItemObjectiveMetadataWidgets.LINKED_ITEMS,
    {
      type: 'HIERARCHY',
      hasChildren: false,
      __typename: 'WorkItemWidgetHierarchy',
    },
  ],
  __typename: 'WorkItem',
};

export const otherNamespaceChild = {
  id: 'gid://gitlab/WorkItem/24',
  iid: '24',
  workItemType: {
    id: 'gid://gitlab/WorkItems::Type/5',
    name: 'Task',
    iconName: 'issue-type-task',
    __typename: 'WorkItemType',
  },
  title: 'baz',
  state: 'OPEN',
  confidential: false,
  reference: 'test-project-path/other#24',
  namespace: {
    fullPath: 'test-project-path/other',
  },
  createdAt: '2022-08-03T12:41:54Z',
  closedAt: null,
  webUrl: '/gitlab-org/gitlab-test/-/work_items/24',
  widgets: [
    workItemObjectiveMetadataWidgets.ASSIGNEES,
    workItemObjectiveMetadataWidgets.LINKED_ITEMS,
  ],
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
    reference: 'test-project-path#1',
    namespace: {
      __typename: 'Project',
      id: '1',
      fullPath: 'test-project-path',
      name: 'Project name',
    },
    createdAt: '2022-08-03T12:41:54Z',
    closedAt: null,
    webUrl: '/gitlab-org/gitlab-test/-/work_items/5',
    widgets: [],
    __typename: 'WorkItem',
  },
];

export const childrenWorkItemsObjectives = [
  {
    id: 'gid://gitlab/WorkItem/5',
    iid: '5',
    workItemType: objectiveType,
    title: 'foobar',
    state: 'OPEN',
    confidential: false,
    reference: 'test-project-path#1',
    namespace: {
      __typename: 'Project',
      id: '1',
      fullPath: 'test-project-path',
      name: 'Project name',
    },
    createdAt: '2022-08-03T12:41:54Z',
    closedAt: null,
    webUrl: '/gitlab-org/gitlab-test/-/work_items/5',
    widgets: [
      {
        type: 'HIERARCHY',
        hasChildren: false,
        rolledUpCountsByType: [],
        __typename: 'WorkItemWidgetHierarchy',
      },
    ],
    __typename: 'WorkItem',
  },
  {
    id: 'gid://gitlab/WorkItem/6',
    iid: '6',
    workItemType: objectiveType,
    title: 'foobar6',
    state: 'OPEN',
    confidential: false,
    reference: 'test-project-path#2',
    namespace: {
      __typename: 'Project',
      id: '1',
      fullPath: 'test-project-path',
      name: 'Project name',
    },
    createdAt: '2022-08-03T12:41:54Z',
    closedAt: null,
    webUrl: '/gitlab-org/gitlab-test/-/work_items/6',
    widgets: [
      {
        type: 'HIERARCHY',
        hasChildren: false,
        rolledUpCountsByType: [],
        __typename: 'WorkItemWidgetHierarchy',
      },
    ],
    __typename: 'WorkItem',
  },
];

export const workItemHierarchyResponse = {
  data: {
    workspace: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/2',
      workItem: {
        id: 'gid://gitlab/WorkItem/1',
        iid: '1',
        archived: false,
        workItemType: {
          id: 'gid://gitlab/WorkItems::Type/1',
          name: 'Issue',
          iconName: 'issue-type-issue',
          __typename: 'WorkItemType',
        },
        title: 'New title',
        webUrl: 'http://gdk.test/gitlab-org/gitlab/-/issues/1',
        userPermissions: {
          deleteWorkItem: true,
          updateWorkItem: true,
          setWorkItemMetadata: true,
          adminParentLink: true,
          createNote: true,
          adminWorkItemLink: true,
          markNoteAsInternal: true,
          reportSpam: false,
          __typename: 'WorkItemPermissions',
        },
        author: {
          ...mockAssignees[0],
        },
        confidential: false,
        namespace: {
          __typename: 'Project',
          id: '1',
          fullPath: 'test-project-path',
          name: 'Project name',
        },
        description: 'Issue description',
        state: 'OPEN',
        createdAt: '2022-08-03T12:41:54Z',
        updatedAt: null,
        closedAt: null,
        reference: 'test-project-path#1',
        createNoteEmail:
          'gitlab-incoming+test-project-path-13fp7g6i9agekcv71s0jx9p58-issue-1@gmail.com',
        widgets: [
          {
            type: 'HIERARCHY',
            parent: null,
            hasChildren: true,
            hasParent: false,
            rolledUpCountsByType: [],
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
  },
};

export const workItemObjectiveWithChild = {
  id: 'gid://gitlab/WorkItem/12',
  iid: '12',
  archived: false,
  workItemType: {
    id: 'gid://gitlab/WorkItems::Type/2411',
    name: 'Objective',
    iconName: 'issue-type-objective',
    __typename: 'WorkItemType',
  },
  webUrl: 'http://gdk.test/gitlab-org/gitlab/-/issues/1',
  namespace: {
    __typename: 'Project',
    id: '1',
    fullPath: 'test-project-path',
    name: 'Project name',
    fullName: 'Group name',
  },
  userPermissions: {
    deleteWorkItem: true,
    updateWorkItem: true,
    setWorkItemMetadata: true,
    adminParentLink: true,
    createNote: true,
    adminWorkItemLink: true,
    markNoteAsInternal: true,
    reportSpam: false,
    __typename: 'WorkItemPermissions',
  },
  author: {
    ...mockAssignees[0],
  },
  title: 'Objective',
  description: 'Objective description',
  state: 'OPEN',
  confidential: false,
  reference: 'test-project-path#12',
  createdAt: '2022-08-03T12:41:54Z',
  updatedAt: null,
  closedAt: null,
  widgets: [
    {
      type: 'HIERARCHY',
      hasChildren: true,
      parent: null,
      rolledUpCountsByType: [],
      children: {
        nodes: [],
      },
      __typename: 'WorkItemWidgetHierarchy',
    },
    workItemObjectiveMetadataWidgets.MILESTONE,
    workItemObjectiveMetadataWidgets.ASSIGNEES,
    workItemObjectiveMetadataWidgets.LABELS,
    workItemObjectiveMetadataWidgets.LINKED_ITEMS,
  ],
  __typename: 'WorkItem',
};

export const workItemWithParentAsChild = {
  id: 'gid://gitlab/WorkItem/1',
  iid: '1',
  title: 'Cyclic parent 1',
  description: 'Objective description',
  state: 'OPEN',
  confidential: false,
  reference: 'test-project-path#12',
  createdAt: '2022-08-03T12:41:54Z',
  updatedAt: null,
  closedAt: null,
  workItemType: {
    id: 'gid://gitlab/WorkItems::Type/2411',
    name: 'Objective',
    iconName: 'issue-type-objective',
    __typename: 'WorkItemType',
  },
  widgets: [
    {
      type: 'HIERARCHY',
      hasChildren: true,
      parent: null,
      rolledUpCountsByType: [],
      children: {
        nodes: [],
      },
      __typename: 'WorkItemWidgetHierarchy',
    },
  ],
  __typename: 'WorkItem',
};

export const workItemObjectiveWithoutChild = {
  id: 'gid://gitlab/WorkItem/12',
  iid: '12',
  archived: false,
  workItemType: {
    id: 'gid://gitlab/WorkItems::Type/2411',
    name: 'Objective',
    iconName: 'issue-type-objective',
    __typename: 'WorkItemType',
  },
  webUrl: 'http://gdk.test/gitlab-org/gitlab/-/issues/1',
  namespace: {
    __typename: 'Project',
    id: '1',
    fullPath: 'test-project-path',
    name: 'Project name',
    fullName: 'Group name',
  },
  userPermissions: {
    deleteWorkItem: true,
    updateWorkItem: true,
    setWorkItemMetadata: true,
    adminParentLink: true,
    createNote: true,
    adminWorkItemLink: true,
    markNoteAsInternal: true,
    reportSpam: false,
    __typename: 'WorkItemPermissions',
  },
  author: {
    ...mockAssignees[0],
  },
  title: 'Objective',
  description: 'Objective description',
  state: 'OPEN',
  confidential: false,
  reference: 'test-project-path#12',
  createdAt: '2022-08-03T12:41:54Z',
  updatedAt: null,
  closedAt: null,
  widgets: [
    {
      type: 'HIERARCHY',
      hasChildren: false,
      parent: null,
      rolledUpCountsByType: [],
      children: {
        nodes: [],
      },
      __typename: 'WorkItemWidgetHierarchy',
    },
    workItemObjectiveMetadataWidgets.MILESTONE,
    workItemObjectiveMetadataWidgets.ASSIGNEES,
    workItemObjectiveMetadataWidgets.LABELS,
    workItemObjectiveMetadataWidgets.LINKED_ITEMS,
  ],
  __typename: 'WorkItem',
};

export const workItemHierarchyTreeEmptyResponse = {
  data: {
    workItem: {
      id: 'gid://gitlab/WorkItem/2',
      iid: '2',
      archived: false,
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
        adminParentLink: true,
        createNote: true,
        adminWorkItemLink: true,
        markNoteAsInternal: true,
        reportSpam: false,
        __typename: 'WorkItemPermissions',
      },
      confidential: false,
      reference: 'test-project-path#2',
      namespace: {
        __typename: 'Project',
        id: '1',
        fullPath: 'test-project-path',
        name: 'Project name',
        fullName: 'Project name',
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
          hasParent: false,
          depthLimitReachedByType: [],
          rolledUpCountsByType: [],
          children: {
            pageInfo: {
              hasNextPage: false,
              hasPreviousPage: false,
              startCursor: null,
              endCursor: null,
              __typename: 'PageInfo',
            },
            count: 0,
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

export const mockHierarchyChildren = [
  {
    id: 'gid://gitlab/WorkItem/31',
    iid: '37',
    workItemType: {
      id: 'gid://gitlab/WorkItems::Type/2411',
      name: 'Objective',
      iconName: 'issue-type-objective',
      __typename: 'WorkItemType',
    },
    namespace: {
      __typename: 'Project',
      id: '1',
      fullPath: 'test-objective-project-path',
      name: 'Project name',
    },
    title: 'Objective 2',
    state: 'OPEN',
    confidential: false,
    reference: 'test-project-path#13',
    createdAt: '2022-08-03T12:41:54Z',
    closedAt: null,
    webUrl: '/gitlab-org/gitlab-test/-/work_items/13',
    widgets: [
      {
        type: 'HIERARCHY',
        hasChildren: true,
        rolledUpCountsByType: [],
        __typename: 'WorkItemWidgetHierarchy',
      },
    ],
    __typename: 'WorkItem',
  },
];

export const mockDepthLimitReachedByType = [
  {
    workItemType: {
      id: 'gid://gitlab/WorkItems::Type/8',
      name: 'Epic',
      __typename: 'WorkItemType',
    },
    depthLimitReached: false,
    __typename: 'WorkItemTypeDepthLimitReachedByType',
  },
];

export const mockHierarchyWidget = {
  type: 'HIERARCHY',
  parent: null,
  hasChildren: true,
  hasParent: false,
  depthLimitReachedByType: mockDepthLimitReachedByType,
  rolledUpCountsByType: mockRolledUpCountsByType,
  children: {
    pageInfo: {
      hasNextPage: false,
      hasPreviousPage: false,
      startCursor: null,
      endCursor: null,
      __typename: 'PageInfo',
    },
    count: 1,
    nodes: mockHierarchyChildren,
    __typename: 'WorkItemConnection',
  },
  __typename: 'WorkItemWidgetHierarchy',
};

export const mockOpenChildrenCount = {
  data: {
    namespace: {
      id: 'gid://gitlab/Group/33',
      workItem: {
        id: 'gid://gitlab/WorkItem/843',
        widgets: [
          {
            type: 'HIERARCHY',
            rolledUpCountsByType: [
              {
                countsByState: {
                  opened: 0,
                  all: 0,
                  closed: 0,
                  __typename: 'WorkItemStateCountsType',
                },
                workItemType: {
                  id: 'gid://gitlab/WorkItems::Type/8',
                  name: 'Epic',
                  iconName: 'issue-type-epic',
                  __typename: 'WorkItemType',
                },
                __typename: 'WorkItemTypeCountsByState',
              },
              {
                countsByState: {
                  opened: 1,
                  all: 1,
                  closed: 0,
                  __typename: 'WorkItemStateCountsType',
                },
                workItemType: {
                  id: 'gid://gitlab/WorkItems::Type/1',
                  name: 'Issue',
                  iconName: 'issue-type-issue',
                  __typename: 'WorkItemType',
                },
                __typename: 'WorkItemTypeCountsByState',
              },
              {
                countsByState: {
                  opened: 0,
                  all: 0,
                  closed: 0,
                  __typename: 'WorkItemStateCountsType',
                },
                workItemType: {
                  id: 'gid://gitlab/WorkItems::Type/5',
                  name: 'Task',
                  iconName: 'issue-type-task',
                  __typename: 'WorkItemType',
                },
                __typename: 'WorkItemTypeCountsByState',
              },
            ],
            __typename: 'WorkItemWidgetHierarchy',
          },
        ],
        __typename: 'WorkItem',
      },
      __typename: 'Namespace',
    },
  },
};

export const mockNoOpenChildrenCount = {
  data: {
    namespace: {
      id: 'gid://gitlab/Group/33',
      workItem: {
        id: 'gid://gitlab/WorkItem/843',
        widgets: [
          {
            type: 'HIERARCHY',
            rolledUpCountsByType: [
              {
                countsByState: {
                  opened: 0,
                  all: 0,
                  closed: 0,
                  __typename: 'WorkItemStateCountsType',
                },
                workItemType: {
                  id: 'gid://gitlab/WorkItems::Type/8',
                  name: 'Epic',
                  iconName: 'issue-type-epic',
                  __typename: 'WorkItemType',
                },
                __typename: 'WorkItemTypeCountsByState',
              },
              {
                countsByState: {
                  opened: 0,
                  all: 0,
                  closed: 0,
                  __typename: 'WorkItemStateCountsType',
                },
                workItemType: {
                  id: 'gid://gitlab/WorkItems::Type/1',
                  name: 'Issue',
                  iconName: 'issue-type-issue',
                  __typename: 'WorkItemType',
                },
                __typename: 'WorkItemTypeCountsByState',
              },
              {
                countsByState: {
                  opened: 0,
                  all: 0,
                  closed: 0,
                  __typename: 'WorkItemStateCountsType',
                },
                workItemType: {
                  id: 'gid://gitlab/WorkItems::Type/5',
                  name: 'Task',
                  iconName: 'issue-type-task',
                  __typename: 'WorkItemType',
                },
                __typename: 'WorkItemTypeCountsByState',
              },
            ],
            __typename: 'WorkItemWidgetHierarchy',
          },
        ],
        __typename: 'WorkItem',
      },
      __typename: 'Namespace',
    },
  },
};

export const workItemHierarchyTreeResponse = {
  data: {
    workItem: {
      id: 'gid://gitlab/WorkItem/2',
      iid: '2',
      archived: false,
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
        adminParentLink: true,
        createNote: true,
        adminWorkItemLink: true,
        markNoteAsInternal: true,
        reportSpam: false,
        __typename: 'WorkItemPermissions',
      },
      confidential: false,
      reference: 'test-project-path#2',
      namespace: {
        __typename: 'Project',
        id: '1',
        fullPath: 'test-project-path',
        name: 'Project name',
        fullName: 'Project name',
      },
      widgets: [
        {
          type: 'DESCRIPTION',
          __typename: 'WorkItemWidgetDescription',
        },
        mockHierarchyWidget,
      ],
      __typename: 'WorkItem',
    },
  },
};

export const workItemHierarchyTreeSingleClosedItemResponse = {
  data: {
    workItem: {
      id: 'gid://gitlab/WorkItem/2',
      iid: '2',
      archived: false,
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
        adminParentLink: true,
        createNote: true,
        adminWorkItemLink: true,
        markNoteAsInternal: true,
        reportSpam: false,
        __typename: 'WorkItemPermissions',
      },
      confidential: false,
      reference: 'test-project-path#2',
      namespace: {
        __typename: 'Project',
        id: '1',
        fullPath: 'test-project-path',
        name: 'Project name',
        fullName: 'Project name',
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
          hasParent: false,
          depthLimitReachedByType: mockDepthLimitReachedByType,
          rolledUpCountsByType: mockRolledUpCountsByType,
          children: {
            pageInfo: {
              hasNextPage: false,
              hasPreviousPage: false,
              startCursor: null,
              endCursor: null,
              __typename: 'PageInfo',
            },
            count: 1,
            nodes: [
              {
                id: 'gid://gitlab/WorkItem/31',
                iid: '37',
                workItemType: {
                  id: 'gid://gitlab/WorkItems::Type/2411',
                  name: 'Objective',
                  iconName: 'issue-type-objective',
                  __typename: 'WorkItemType',
                },
                namespace: {
                  __typename: 'Project',
                  id: '1',
                  fullPath: 'test-objective-project-path',
                  name: 'Project name',
                },
                title: 'Objective 2',
                state: 'CLOSED',
                confidential: false,
                reference: 'test-project-path#13',
                createdAt: '2022-08-03T12:41:54Z',
                closedAt: null,
                webUrl: '/gitlab-org/gitlab-test/-/work_items/13',
                widgets: [
                  {
                    type: 'HIERARCHY',
                    hasChildren: true,
                    rolledUpCountsByType: [],
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

export const workItemHierarchyPaginatedTreeResponse = {
  data: {
    workItem: {
      ...workItemHierarchyTreeResponse.data.workItem,
      widgets: [
        {
          type: 'DESCRIPTION',
          __typename: 'WorkItemWidgetDescription',
        },
        {
          ...mockHierarchyWidget,
          children: {
            count: 2,
            pageInfo: {
              hasNextPage: true,
              hasPreviousPage: false,
              startCursor: 'Y3Vyc29yOjE=',
              endCursor: 'Y3Vyc29yOjE=',
              __typename: 'PageInfo',
            },
            nodes: mockHierarchyChildren,
            __typename: 'WorkItemConnection',
          },
        },
      ],
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

export const workItemObjectiveWithClosedChild = {
  id: 'gid://gitlab/WorkItem/12',
  iid: '12',
  archived: false,
  workItemType: {
    id: 'gid://gitlab/WorkItems::Type/2411',
    name: 'Objective',
    iconName: 'issue-type-objective',
    __typename: 'WorkItemType',
  },
  namespace: {
    __typename: 'Project',
    id: '1',
    fullPath: 'test-project-path',
    name: 'Project name',
  },
  userPermissions: {
    deleteWorkItem: true,
    updateWorkItem: true,
    setWorkItemMetadata: true,
    adminParentLink: true,
    createNote: true,
    adminWorkItemLink: true,
    markNoteAsInternal: true,
    reportSpam: false,
    __typename: 'WorkItemPermissions',
  },
  author: {
    ...mockAssignees[0],
  },
  title: 'Objective',
  description: 'Objective description',
  state: 'OPEN',
  confidential: false,
  reference: 'test-project-path#12',
  createdAt: '2022-08-03T12:41:54Z',
  updatedAt: null,
  closedAt: null,
  widgets: [
    {
      type: 'HIERARCHY',
      hasChildren: true,
      parent: null,
      rolledUpCountsByType: [
        {
          countsByState: {
            all: 1,
            closed: 1,
            __typename: 'WorkItemStateCountsType',
          },
          workItemType: {
            id: 'gid://gitlab/WorkItems::Type/1',
            name: 'Issue',
            iconName: 'issue-type-issue',
            __typename: 'WorkItemType',
          },
          __typename: 'WorkItemTypeCountsByState',
        },
      ],
      children: {
        nodes: mockHierarchyChildren.map((c) => ({ ...c, state: STATE_CLOSED })),
      },
      __typename: 'WorkItemWidgetHierarchy',
    },
    workItemObjectiveMetadataWidgets.MILESTONE,
    workItemObjectiveMetadataWidgets.ASSIGNEES,
    workItemObjectiveMetadataWidgets.LABELS,
    workItemObjectiveMetadataWidgets.LINKED_ITEMS,
  ],
  __typename: 'WorkItem',
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
          adminParentLink: true,
          createNote: true,
          adminWorkItemLink: true,
          markNoteAsInternal: true,
          reportSpam: false,
          __typename: 'WorkItemPermissions',
        },
        description: null,
        webUrl: 'http://gdk.test/gitlab-org/gitlab/-/issues/1',
        id: 'gid://gitlab/WorkItem/2',
        iid: '2',
        archived: false,
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
          id: 'gid://gitlab/Project/7',
          __typename: 'Project',
        },
        namespace: {
          __typename: 'Project',
          id: '1',
          fullPath: 'test-project-path',
          name: 'Project name',
          fullName: 'Group name',
        },
        reference: 'test-project-path#2',
        createNoteEmail:
          'gitlab-incoming+test-project-path-13fp7g6i9agekcv71s0jx9p58-issue-2@gmail.com',
        widgets: [
          {
            __typename: 'WorkItemWidgetHierarchy',
            type: 'HIERARCHY',
            hasParent: false,
            parent: null,
            hasChildren: false,
            rolledUpCountsByType: [],
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
            iid: '2',
            title: 'Task 1',
            confidential: false,
            __typename: 'WorkItem',
          },
          {
            id: 'gid://gitlab/WorkItem/459',
            iid: '3',
            title: 'Task 2',
            confidential: false,
            __typename: 'WorkItem',
          },
          {
            id: 'gid://gitlab/WorkItem/460',
            iid: '4',
            title: 'Task 3',
            confidential: false,
            __typename: 'WorkItem',
          },
        ],
      },
    },
  },
};

export const availableObjectivesResponse = {
  data: {
    workspace: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/2',
      workItems: {
        nodes: [
          {
            id: 'gid://gitlab/WorkItem/716',
            iid: '122',
            title: 'Objective 101',
            confidential: false,
            __typename: 'WorkItem',
          },
          {
            id: 'gid://gitlab/WorkItem/712',
            iid: '118',
            title: 'Objective 103',
            confidential: false,
            __typename: 'WorkItem',
          },
          {
            id: 'gid://gitlab/WorkItem/711',
            iid: '117',
            title: 'Objective 102',
            confidential: false,
            __typename: 'WorkItem',
          },
        ],
      },
    },
  },
};

export const searchedObjectiveResponse = {
  data: {
    workspace: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/2',
      workItems: {
        nodes: [
          {
            id: 'gid://gitlab/WorkItem/716',
            iid: '122',
            title: 'Objective 101',
            confidential: false,
            __typename: 'WorkItem',
          },
        ],
      },
    },
  },
};

export const searchWorkItemsResponse = ({ workItems = [], workItemsByIid = [] } = {}) => {
  return {
    data: {
      workspace: {
        __typename: 'Project',
        id: 'gid://gitlab/Project/2',
        workItems: {
          nodes: workItems,
        },
        workItemsByIid: {
          nodes: workItemsByIid,
        },
      },
    },
  };
};

export const projectMembersAutocompleteResponseWithCurrentUser = {
  data: {
    workspace: {
      id: 'gid://gitlab/Project/7',
      __typename: 'Project',
      users: [
        {
          __typename: 'AutocompletedUser',
          id: 'gid://gitlab/User/5',
          avatarUrl: '/avatar2',
          name: 'rookie',
          username: 'rookie',
          webUrl: 'rookie',
          webPath: '/rookie',
          status: null,
        },
        {
          __typename: 'AutocompletedUser',
          id: 'gid://gitlab/User/1',
          avatarUrl:
            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
          name: 'Administrator',
          username: 'root',
          webUrl: '/root',
          webPath: '/root',
          status: null,
        },
      ],
    },
  },
};

export const projectMembersAutocompleteResponseWithNoMatchingUsers = {
  data: {
    workspace: {
      id: '1',
      __typename: 'Project',
      users: [],
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
      webPath: '/root',
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

export const groupLabelsResponse = {
  data: {
    workspace: {
      id: '1',
      __typename: 'Group',
      labels: {
        nodes: mockLabels,
      },
    },
  },
};

export const getProjectLabelsResponse = (labels) => ({
  data: {
    workspace: {
      id: '1',
      __typename: 'Project',
      labels: {
        nodes: labels,
      },
    },
  },
});

export const getGroupCrmContactsResponse = (contacts) => ({
  data: {
    group: {
      id: '1',
      contacts: {
        nodes: contacts,
        pageInfo: {
          hasNextPage: false,
          endCursor: null,
          hasPreviousPage: false,
          startCursor: null,
        },
      },
    },
  },
});

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

export const mockEmptyAncestorWidgetResponse = {
  data: {
    workItemUpdate: {
      workItem: {
        id: 'gid://gitlab/WorkItem/2733',
        title: 'Objective progress child 1',
        widgets: [
          {
            type: 'HIERARCHY',
            hasParent: false,
            parent: null,
            ancestors: {
              nodes: [],
              __typename: 'WorkItemConnection',
            },
            __typename: 'WorkItemWidgetHierarchy',
          },
        ],
        __typename: 'WorkItem',
      },
      errors: [],
      __typename: 'WorkItemUpdatePayload',
    },
  },
};

export const mockParentWidgetResponse = {
  id: 'gid://gitlab/WorkItem/716',
  iid: '122',
  title: 'Objective 101',
  confidential: false,
  webUrl: 'http://127.0.0.1:3000/gitlab-org/gitlab-test/-/work_items/122',
  workItemType: {
    id: 'gid://gitlab/WorkItems::Type/6',
    name: 'Objective',
    iconName: 'issue-type-objective',
    __typename: 'WorkItemType',
  },
  __typename: 'WorkItem',
};

export const mockAncestorWidgetResponse = {
  data: {
    workItemUpdate: {
      workItem: {
        id: 'gid://gitlab/WorkItem/2733',
        title: 'Objective progress child 1',
        widgets: [
          {
            type: 'HIERARCHY',
            hasParent: true,
            parent: {
              id: 'gid://gitlab/WorkItem/1296',
              iid: '149',
              title: 'Objective 333',
              confidential: false,
              webUrl: 'http://gdk.test:3000/gitlab-org/gitlab-test/-/work_items/149',
              workItemType: {
                id: 'gid://gitlab/WorkItems::Type/6',
                name: 'Objective',
                iconName: 'issue-type-objective',
                __typename: 'WorkItemType',
              },
              __typename: 'WorkItem',
            },
            ancestors: {
              nodes: [
                {
                  id: 'gid://gitlab/WorkItem/663',
                  iid: '71',
                  confidential: false,
                  workItemType: {
                    id: 'gid://gitlab/WorkItems::Type/6',
                    name: 'Objective',
                    iconName: 'issue-type-objective',
                    __typename: 'WorkItemType',
                  },
                  title: 'Objective 3',
                  state: 'OPEN',
                  reference: 'gitlab-org/gitlab-test#71',
                  createdAt: '2023-04-24T10:48:19Z',
                  closedAt: null,
                  webUrl: 'http://gdk.test:3000/gitlab-org/gitlab-test/-/work_items/71',
                  widgets: [
                    {
                      type: 'HIERARCHY',
                      hasParent: false,
                      parent: null,
                      __typename: 'WorkItemWidgetHierarchy',
                    },
                  ],
                  __typename: 'WorkItem',
                },
                {
                  id: 'gid://gitlab/WorkItem/1296',
                  iid: '149',
                  confidential: false,
                  workItemType: {
                    id: 'gid://gitlab/WorkItems::Type/6',
                    name: 'Objective',
                    iconName: 'issue-type-objective',
                    __typename: 'WorkItemType',
                  },
                  title: 'Objective 333',
                  state: 'OPEN',
                  reference: 'gitlab-org/gitlab-test#149',
                  createdAt: '2023-12-18T16:54:47Z',
                  closedAt: null,
                  webUrl: 'http://gdk.test:3000/gitlab-org/gitlab-test/-/work_items/149',
                  widgets: [
                    {
                      type: 'HIERARCHY',
                      hasParent: true,
                      parent: {
                        id: 'gid://gitlab/WorkItem/663',
                        __typename: 'WorkItem',
                      },
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
      errors: [],
      __typename: 'WorkItemUpdatePayload',
    },
  },
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

export const mockWorkItemNotesResponse = {
  data: {
    workItem: {
      id: 'gid://gitlab/WorkItem/1',
      iid: '60',
      namespace: {
        id: 'gid://gitlab/Namespaces::ProjectNamespace/34',
        __typename: 'Namespace',
      },
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
                      url: 'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37#note_199',
                      lastEditedBy: null,
                      system: true,
                      internal: false,
                      maxAccessLevelOfAuthor: 'Owner',
                      authorIsContributor: false,
                      externalAuthor: null,
                      discussion: {
                        id: 'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da12723561234',
                        resolved: false,
                        resolvable: false,
                        resolvedBy: null,
                        __typename: 'Discussion',
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
                      systemNoteMetadata: {
                        id: 'gid://gitlab/SystemNoteMetadata/36',
                        descriptionVersion: null,
                      },
                      author: {
                        avatarUrl:
                          'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                        id: 'gid://gitlab/User/1',
                        name: 'Administrator',
                        username: 'root',
                        webUrl: 'http://127.0.0.1:3000/root',
                        webPath: '/root',
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
                      systemNoteIconName: 'milestone',
                      createdAt: '2022-11-14T04:18:59Z',
                      lastEditedAt: null,
                      url: 'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37#note_201',
                      lastEditedBy: null,
                      system: true,
                      internal: false,
                      maxAccessLevelOfAuthor: 'Owner',
                      authorIsContributor: false,
                      externalAuthor: null,
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
                      systemNoteMetadata: {
                        id: 'gid://gitlab/SystemNoteMetadata/76',
                        descriptionVersion: null,
                      },
                      author: {
                        avatarUrl:
                          'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                        id: 'gid://gitlab/User/1',
                        name: 'Administrator',
                        username: 'root',
                        webUrl: 'http://127.0.0.1:3000/root',
                        webPath: '/root',
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
                      url: 'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37#note_202',
                      lastEditedBy: null,
                      system: true,
                      internal: false,
                      maxAccessLevelOfAuthor: 'Owner',
                      authorIsContributor: false,
                      externalAuthor: null,
                      discussion: {
                        id: 'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da12723560987',
                        resolved: false,
                        resolvable: false,
                        resolvedBy: null,
                        __typename: 'Discussion',
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
                      systemNoteMetadata: {
                        id: 'gid://gitlab/SystemNoteMetadata/71',
                        descriptionVersion: null,
                      },
                      author: {
                        avatarUrl:
                          'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                        id: 'gid://gitlab/User/1',
                        name: 'Administrator',
                        username: 'root',
                        webUrl: 'http://127.0.0.1:3000/root',
                        webPath: '/root',
                        __typename: 'UserCore',
                      },
                      awardEmoji: {
                        nodes: [],
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
      workItem: {
        id: 'gid://gitlab/WorkItem/600',
        iid: '51',
        namespace: {
          id: 'gid://gitlab/Namespaces::ProjectNamespace/34',
          __typename: 'Namespace',
        },
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
            discussionLocked: false,
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
                        url: 'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37#note_191',
                        lastEditedBy: null,
                        system: true,
                        internal: false,
                        maxAccessLevelOfAuthor: null,
                        authorIsContributor: false,
                        externalAuthor: null,
                        discussion: {
                          id: 'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da12723561234',
                          resolved: false,
                          resolvable: false,
                          resolvedBy: null,
                          __typename: 'Discussion',
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
                        systemNoteMetadata: {
                          id: 'gid://gitlab/SystemNoteMetadata/72',
                          descriptionVersion: null,
                        },
                        author: {
                          id: 'gid://gitlab/User/1',
                          avatarUrl:
                            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
                          name: 'Administrator',
                          username: 'root',
                          webUrl: 'http://127.0.0.1:3000/root',
                          webPath: '/root',
                          __typename: 'UserCore',
                        },
                        awardEmoji: {
                          nodes: [],
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
                        id: 'gid://gitlab/MilestoneNote/7b08b89a728a5ceb7de8334246837ba1d07270dc',
                        body: 'changed milestone to %v4.0',
                        bodyHtml:
                          '\u003cp data-sourcepos="1:1-1:23" dir="auto"\u003echanged milestone to \u003ca href="/flightjs/Flight/-/milestones/5" data-reference-type="milestone" data-original="%5" data-link="false" data-link-reference="false" data-project="6" data-milestone="30" data-container="body" data-placement="top" title="" class="gfm gfm-milestone has-tooltip"\u003e%v4.0\u003c/a\u003e\u003c/p\u003e',
                        systemNoteIconName: 'milestone',
                        createdAt: '2022-11-14T04:18:59Z',
                        lastEditedAt: null,
                        url: 'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37#note_191',
                        lastEditedBy: null,
                        system: true,
                        internal: false,
                        maxAccessLevelOfAuthor: null,
                        authorIsContributor: false,
                        externalAuthor: null,
                        discussion: {
                          id: 'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da12723568765',
                          resolved: false,
                          resolvable: false,
                          resolvedBy: null,
                          __typename: 'Discussion',
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
                        systemNoteMetadata: {
                          id: 'gid://gitlab/SystemNoteMetadata/76',
                          descriptionVersion: null,
                        },
                        author: {
                          id: 'gid://gitlab/User/1',
                          avatarUrl:
                            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
                          name: 'Administrator',
                          username: 'root',
                          webUrl: 'http://127.0.0.1:3000/root',
                          webPath: '/root',
                          __typename: 'UserCore',
                        },
                        awardEmoji: {
                          nodes: [],
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
                        id: 'gid://gitlab/IterationNote/addbc177f7664699a135130ab05ffb78c57e4db3',
                        body: 'changed iteration to Et autem debitis nam suscipit eos ut. Jul 13, 2022 - Jul 19, 2022',
                        bodyHtml:
                          '\u003cp data-sourcepos="1:1-1:36" dir="auto"\u003echanged iteration to \u003ca href="/groups/flightjs/-/iterations/5352" data-reference-type="iteration" data-original="*iteration:5352" data-link="false" data-link-reference="false" data-project="6" data-iteration="5352" data-container="body" data-placement="top" title="Iteration" class="gfm gfm-iteration has-tooltip"\u003eEt autem debitis nam suscipit eos ut. Jul 13, 2022 - Jul 19, 2022\u003c/a\u003e\u003c/p\u003e',
                        systemNoteIconName: 'iteration',
                        createdAt: '2022-11-14T04:19:00Z',
                        lastEditedAt: null,
                        url: 'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37#note_191',
                        lastEditedBy: null,
                        system: true,
                        internal: false,
                        maxAccessLevelOfAuthor: null,
                        authorIsContributor: false,
                        externalAuthor: null,
                        discussion: {
                          id: 'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da12723569876',
                          resolved: false,
                          resolvable: false,
                          resolvedBy: null,
                          __typename: 'Discussion',
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
                        systemNoteMetadata: {
                          id: 'gid://gitlab/SystemNoteMetadata/22',
                          descriptionVersion: null,
                        },
                        author: {
                          id: 'gid://gitlab/User/1',
                          avatarUrl:
                            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
                          name: 'Administrator',
                          username: 'root',
                          webUrl: 'http://127.0.0.1:3000/root',
                          webPath: '/root',
                          __typename: 'UserCore',
                        },
                        awardEmoji: {
                          nodes: [],
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
    __typename: 'Project',
  },
};

export const mockMoreWorkItemNotesResponse = {
  data: {
    workspace: {
      id: 'gid://gitlab/Project/6',
      workItem: {
        id: 'gid://gitlab/WorkItem/600',
        iid: '60',
        namespace: {
          id: 'gid://gitlab/Namespaces::ProjectNamespace/34',
          __typename: 'Namespace',
        },
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
            discussionLocked: false,
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
                        url: 'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37#note_191',
                        lastEditedBy: null,
                        system: true,
                        internal: false,
                        maxAccessLevelOfAuthor: 'Owner',
                        authorIsContributor: false,
                        externalAuthor: null,
                        discussion: {
                          id: 'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da1112356a59e',
                          resolved: false,
                          resolvable: false,
                          resolvedBy: null,
                          __typename: 'Discussion',
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
                        systemNoteMetadata: {
                          id: 'gid://gitlab/SystemNoteMetadata/16',
                          descriptionVersion: null,
                        },
                        author: {
                          avatarUrl:
                            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                          id: 'gid://gitlab/User/1',
                          name: 'Administrator',
                          username: 'root',
                          webUrl: 'http://127.0.0.1:3000/root',
                          webPath: '/root',
                          __typename: 'UserCore',
                        },
                        awardEmoji: {
                          nodes: [],
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
                        id: 'gid://gitlab/MilestoneNote/0f2f195ec0d1ef95ee9d5b10446b8e96a7d83823',
                        body: 'changed milestone to %v4.0',
                        bodyHtml:
                          '<p data-sourcepos="1:1-1:23" dir="auto">changed milestone to <a href="/flightjs/Flight/-/milestones/5" data-reference-type="milestone" data-original="%5" data-link="false" data-link-reference="false" data-project="6" data-milestone="30" data-container=body data-placement="top" title="" class="gfm gfm-milestone has-tooltip">%v4.0</a></p>',
                        systemNoteIconName: 'milestone',
                        createdAt: '2022-11-14T04:18:59Z',
                        lastEditedAt: null,
                        url: 'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37#note_191',
                        lastEditedBy: null,
                        system: true,
                        internal: false,
                        maxAccessLevelOfAuthor: 'Owner',
                        authorIsContributor: false,
                        externalAuthor: null,
                        discussion: {
                          id: 'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da1272356a59e',
                          resolved: false,
                          resolvable: false,
                          resolvedBy: null,
                          __typename: 'Discussion',
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
                        systemNoteMetadata: {
                          id: 'gid://gitlab/SystemNoteMetadata/96',
                          descriptionVersion: null,
                        },
                        author: {
                          avatarUrl:
                            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                          id: 'gid://gitlab/User/1',
                          name: 'Administrator',
                          username: 'root',
                          webUrl: 'http://127.0.0.1:3000/root',
                          webPath: '/root',
                          __typename: 'UserCore',
                        },
                        awardEmoji: {
                          nodes: [],
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
                        url: 'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37#note_191',
                        lastEditedBy: null,
                        system: true,
                        internal: false,
                        maxAccessLevelOfAuthor: 'Owner',
                        authorIsContributor: false,
                        externalAuthor: null,
                        discussion: {
                          id: 'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da12723569876',
                          resolved: false,
                          resolvable: false,
                          resolvedBy: null,
                          __typename: 'Discussion',
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
                        systemNoteMetadata: {
                          id: 'gid://gitlab/SystemNoteMetadata/56',
                          descriptionVersion: null,
                        },
                        author: {
                          avatarUrl:
                            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                          id: 'gid://gitlab/User/1',
                          name: 'Administrator',
                          username: 'root',
                          webUrl: 'http://127.0.0.1:3000/root',
                          webPath: '/root',
                          __typename: 'UserCore',
                        },
                        awardEmoji: {
                          nodes: [],
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
  },
};

export const createWorkItemNoteResponse = ({
  errors = [],
  errorMessages = null,
  messages = null,
} = {}) => ({
  data: {
    createNote: {
      errors,
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
                url: 'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37#note_191',
                lastEditedBy: null,
                maxAccessLevelOfAuthor: 'Owner',
                authorIsContributor: false,
                externalAuthor: null,
                discussion: {
                  id: 'gid://gitlab/Discussion/c872ba2d7d3eb780d2255138d67ca8b04f65b122',
                  resolved: false,
                  resolvable: true,
                  resolvedBy: null,
                  __typename: 'Discussion',
                },
                author: {
                  id: 'gid://gitlab/User/1',
                  avatarUrl:
                    'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                  name: 'Administrator',
                  username: 'root',
                  webUrl: 'http://127.0.0.1:3000/root',
                  webPath: '/root',
                  __typename: 'UserCore',
                },
                systemNoteMetadata: null,
                userPermissions: {
                  adminNote: true,
                  awardEmoji: true,
                  readNote: true,
                  createNote: true,
                  resolveNote: true,
                  repositionNote: true,
                  __typename: 'NotePermissions',
                },
                awardEmoji: {
                  nodes: [],
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
      quickActionsStatus: {
        errorMessages,
        messages,
      },
      __typename: 'CreateNotePayload',
    },
  },
});

export const mockWorkItemCommentNote = {
  id: 'gid://gitlab/Note/158',
  body: 'How are you ? what do you think about this ?',
  bodyHtml:
    '<p data-sourcepos="1:1-1:76" dir="auto"><gl-emoji title="waving hand sign" data-name="wave" data-unicode-version="6.0">👋</gl-emoji> Hi <a href="/fredda.brekke" data-reference-type="user" data-user="3" data-container="body" data-placement="top" class="gfm gfm-project_member js-user-link" title="Sherie Nitzsche">@fredda.brekke</a> How are you ? what do you think about this ? <gl-emoji title="person with folded hands" data-name="pray" data-unicode-version="6.0">🙏</gl-emoji></p>',
  systemNoteIconName: false,
  createdAt: '2022-11-25T07:16:20Z',
  lastEditedAt: null,
  url: 'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37#note_191',
  lastEditedBy: null,
  system: false,
  internal: false,
  maxAccessLevelOfAuthor: 'Owner',
  authorIsContributor: false,
  externalAuthor: null,
  discussion: {
    id: 'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da12723569876',
    resolved: false,
    resolvable: true,
    resolvedBy: null,
    __typename: 'Discussion',
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
  systemNoteMetadata: null,
  author: {
    avatarUrl: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
    id: 'gid://gitlab/User/1',
    name: 'Administrator',
    username: 'root',
    webUrl: 'http://127.0.0.1:3000/root',
    webPath: '/root',
    __typename: 'UserCore',
  },
  awardEmoji: {
    nodes: [mockAwardEmojiThumbsDown],
  },
};

export const mockWorkItemCommentNoteByContributor = {
  ...mockWorkItemCommentNote,
  authorIsContributor: true,
};

export const mockWorkItemCommentByMaintainer = {
  ...mockWorkItemCommentNote,
  maxAccessLevelOfAuthor: 'Maintainer',
};

export const mockWorkItemNotesResponseWithComments = (resolved = false) => {
  return {
    data: {
      workspace: {
        id: 'gid://gitlab/Project/6',
        workItem: {
          id: 'gid://gitlab/WorkItem/600',
          iid: '60',
          namespace: {
            id: 'gid://gitlab/Namespaces::ProjectNamespace/34',
            __typename: 'Namespace',
          },
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
              discussionLocked: false,
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
                          url: 'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37#note_191',
                          lastEditedBy: null,
                          maxAccessLevelOfAuthor: 'Owner',
                          authorIsContributor: false,
                          externalAuthor: null,
                          discussion: {
                            id: 'gid://gitlab/Discussion/2bb1162fd0d39297d1a68fdd7d4083d3780af0f3',
                            resolved,
                            resolvable: true,
                            resolvedBy: null,
                            __typename: 'Discussion',
                          },
                          author: {
                            id: 'gid://gitlab/User/1',
                            avatarUrl:
                              'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                            name: 'Administrator',
                            username: 'root',
                            webUrl: 'http://127.0.0.1:3000/root',
                            webPath: '/root',
                            __typename: 'UserCore',
                          },
                          systemNoteMetadata: null,
                          userPermissions: {
                            adminNote: true,
                            awardEmoji: true,
                            readNote: true,
                            createNote: true,
                            resolveNote: true,
                            repositionNote: true,
                            __typename: 'NotePermissions',
                          },
                          awardEmoji: {
                            nodes: [mockAwardEmojiThumbsDown],
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
                          url: 'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37#note_191',
                          lastEditedBy: null,
                          maxAccessLevelOfAuthor: 'Owner',
                          authorIsContributor: false,
                          externalAuthor: null,
                          discussion: {
                            id: 'gid://gitlab/Discussion/2bb1162fd0d39297d1a68fdd7d4083d3780af0f3',
                            resolved,
                            resolvable: true,
                            resolvedBy: null,
                            __typename: 'Discussion',
                          },
                          author: {
                            id: 'gid://gitlab/User/1',
                            avatarUrl:
                              'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                            name: 'Administrator',
                            username: 'root',
                            webUrl: 'http://127.0.0.1:3000/root',
                            webPath: '/root',
                            __typename: 'UserCore',
                          },
                          systemNoteMetadata: null,
                          userPermissions: {
                            adminNote: true,
                            awardEmoji: true,
                            readNote: true,
                            createNote: true,
                            resolveNote: true,
                            repositionNote: true,
                            __typename: 'NotePermissions',
                          },
                          awardEmoji: {
                            nodes: [],
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
                          url: 'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37#note_191',
                          lastEditedBy: null,
                          system: false,
                          internal: false,
                          maxAccessLevelOfAuthor: 'Owner',
                          authorIsContributor: false,
                          externalAuthor: null,
                          discussion: {
                            id: 'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da12723560987',
                            resolved,
                            resolvable: true,
                            resolvedBy: null,
                            __typename: 'Discussion',
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
                          systemNoteMetadata: null,
                          author: {
                            avatarUrl:
                              'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                            id: 'gid://gitlab/User/1',
                            name: 'Administrator',
                            username: 'root',
                            webUrl: 'http://127.0.0.1:3000/root',
                            webPath: '/root',
                            __typename: 'UserCore',
                          },
                          awardEmoji: {
                            nodes: [],
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
    },
  };
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
      url: 'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37#note_191',
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
              url: 'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37#note_191',
              lastEditedBy: null,
              system: true,
              internal: false,
              maxAccessLevelOfAuthor: 'Owner',
              authorIsContributor: false,
              externalAuthor: null,
              discussion: {
                id: 'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da12723560987',
                resolved: false,
                resolvable: false,
                resolvedBy: null,
                __typename: 'Discussion',
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
              systemNoteMetadata: {
                id: 'gid://gitlab/SystemNoteMetadata/65',
                descriptionVersion: null,
              },
              author: {
                avatarUrl:
                  'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                id: 'gid://gitlab/User/1',
                name: 'Administrator',
                username: 'root',
                webUrl: 'http://127.0.0.1:3000/root',
                webPath: '/root',
                __typename: 'UserCore',
              },
              awardEmoji: {
                nodes: [],
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
      systemNoteMetadata: {
        id: 'gid://gitlab/SystemNoteMetadata/26',
        descriptionVersion: null,
      },
      author: {
        avatarUrl:
          'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
        id: 'gid://gitlab/User/1',
        name: 'Administrator',
        username: 'root',
        webUrl: 'http://127.0.0.1:3000/root',
        webPath: '/root',
        __typename: 'UserCore',
      },
      awardEmoji: {
        nodes: [],
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
      url: 'http://127.0.0.1:3000/flightjs/Flight/-/work_items/37#note_191',
      lastEditedBy: null,
      system: true,
      internal: false,
      maxAccessLevelOfAuthor: 'Owner',
      authorIsContributor: false,
      externalAuthor: null,
      discussion: {
        id: 'gid://gitlab/Discussion/9c17769ca29798eddaed539d010da12723560987',
        resolved: false,
        resolvable: false,
        resolvedBy: null,
        __typename: 'Discussion',
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
      systemNoteMetadata: {
        id: 'gid://gitlab/SystemNoteMetadata/46',
        descriptionVersion: null,
      },
      author: {
        avatarUrl:
          'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
        id: 'gid://gitlab/User/1',
        name: 'Administrator',
        username: 'root',
        webUrl: 'http://127.0.0.1:3000/root',
        webPath: '/root',
        __typename: 'UserCore',
      },
      awardEmoji: {
        nodes: [],
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

export const workItemSystemNoteWithMetadata = {
  id: 'gid://gitlab/Note/1651',
  body: 'changed the description',
  bodyHtml: '<p data-sourcepos="1:1-1:23" dir="auto">changed the description</p>',
  system: true,
  internal: false,
  systemNoteIconName: 'pencil',
  createdAt: '2023-05-05T07:19:37Z',
  lastEditedAt: '2023-05-05T07:19:37Z',
  url: 'https://gdk.test:3443/flightjs/Flight/-/work_items/46#note_1651',
  lastEditedBy: null,
  maxAccessLevelOfAuthor: 'Owner',
  authorIsContributor: false,
  externalAuthor: null,
  discussion: {
    id: 'gid://gitlab/Discussion/7d4a46ea0525e2eeed451f7b718b0ebe73205374',
    resolved: false,
    resolvable: false,
    resolvedBy: null,
    __typename: 'Discussion',
  },
  author: {
    id: 'gid://gitlab/User/1',
    avatarUrl:
      'https://secure.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
    name: 'Administrator',
    username: 'root',
    webUrl: 'https://gdk.test:3443/root',
    webPath: '/root',
    __typename: 'UserCore',
  },
  userPermissions: {
    adminNote: false,
    awardEmoji: true,
    readNote: true,
    createNote: true,
    resolveNote: true,
    repositionNote: false,
    __typename: 'NotePermissions',
  },
  systemNoteMetadata: {
    id: 'gid://gitlab/SystemNoteMetadata/670',
    descriptionVersion: {
      id: 'gid://gitlab/DescriptionVersion/167',
      description: '5th May 90 987',
      diff: '<span class="idiff">5th May 90</span><span class="idiff addition"> 987</span>',
      diffPath: '/flightjs/Flight/-/issues/46/descriptions/167/diff',
      deletePath: '/flightjs/Flight/-/issues/46/descriptions/167',
      canDelete: true,
      deleted: false,
      startVersionId: '',
      __typename: 'DescriptionVersion',
    },
    __typename: 'SystemNoteMetadata',
  },
  __typename: 'Note',
};

export const workItemNotesWithSystemNotesWithChangedDescription = {
  data: {
    workspace: {
      id: 'gid://gitlab/Project/4',
      workItem: {
        id: 'gid://gitlab/WorkItem/733',
        iid: '79',
        namespace: {
          id: 'gid://gitlab/Namespaces::ProjectNamespace/34',
          __typename: 'Namespace',
        },
        widgets: [
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
            __typename: 'WorkItemWidgetMilestone',
          },
          {
            type: 'NOTES',
            discussionLocked: false,
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
                  id: 'gid://gitlab/Discussion/aa72f4c2f3eef66afa6d79a805178801ce4bd89f',
                  notes: {
                    nodes: [
                      {
                        id: 'gid://gitlab/Note/1687',
                        body: 'changed the description',
                        bodyHtml:
                          '<p data-sourcepos="1:1-1:23" dir="auto">changed the description</p>',
                        system: true,
                        internal: false,
                        systemNoteIconName: 'pencil',
                        createdAt: '2023-05-10T05:21:01Z',
                        lastEditedAt: '2023-05-10T05:21:01Z',
                        url: 'https://gdk.test:3443/gnuwget/Wget2/-/work_items/79#note_1687',
                        lastEditedBy: null,
                        maxAccessLevelOfAuthor: 'Owner',
                        authorIsContributor: false,
                        externalAuthor: null,
                        discussion: {
                          id: 'gid://gitlab/Discussion/aa72f4c2f3eef66afa6d79a805178801ce4bd89f',
                          resolved: false,
                          resolvable: false,
                          resolvedBy: null,
                          __typename: 'Discussion',
                        },
                        author: {
                          id: 'gid://gitlab/User/1',
                          avatarUrl:
                            'https://secure.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                          name: 'Administrator',
                          username: 'root',
                          webUrl: 'https://gdk.test:3443/root',
                          webPath: '/root',
                          __typename: 'UserCore',
                        },
                        userPermissions: {
                          adminNote: false,
                          awardEmoji: true,
                          readNote: true,
                          createNote: true,
                          resolveNote: true,
                          repositionNote: false,
                          __typename: 'NotePermissions',
                        },
                        systemNoteMetadata: {
                          id: 'gid://gitlab/SystemNoteMetadata/703',
                          descriptionVersion: {
                            id: 'gid://gitlab/DescriptionVersion/198',
                            description: 'Desc1',
                            diff: '<span class="idiff addition">Desc1</span>',
                            diffPath: '/gnuwget/Wget2/-/issues/79/descriptions/198/diff',
                            deletePath: '/gnuwget/Wget2/-/issues/79/descriptions/198',
                            canDelete: true,
                            deleted: false,
                            __typename: 'DescriptionVersion',
                          },
                          __typename: 'SystemNoteMetadata',
                        },
                        awardEmoji: {
                          nodes: [],
                        },
                        __typename: 'Note',
                      },
                    ],
                    __typename: 'NoteConnection',
                  },
                  __typename: 'Discussion',
                },
                {
                  id: 'gid://gitlab/Discussion/a7d3cf7bd72f7a98f802845f538af65cb11a02cc',
                  notes: {
                    nodes: [
                      {
                        id: 'gid://gitlab/Note/1688',
                        body: 'changed the description',
                        bodyHtml:
                          '<p data-sourcepos="1:1-1:23" dir="auto">changed the description</p>',
                        system: true,
                        internal: false,
                        systemNoteIconName: 'pencil',
                        createdAt: '2023-05-10T05:21:05Z',
                        lastEditedAt: '2023-05-10T05:21:05Z',
                        url: 'https://gdk.test:3443/gnuwget/Wget2/-/work_items/79#note_1688',
                        lastEditedBy: null,
                        maxAccessLevelOfAuthor: 'Owner',
                        authorIsContributor: false,
                        externalAuthor: null,
                        discussion: {
                          id: 'gid://gitlab/Discussion/a7d3cf7bd72f7a98f802845f538af65cb11a02cc',
                          resolved: false,
                          resolvable: false,
                          resolvedBy: null,
                          __typename: 'Discussion',
                        },
                        author: {
                          id: 'gid://gitlab/User/1',
                          avatarUrl:
                            'https://secure.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                          name: 'Administrator',
                          username: 'root',
                          webUrl: 'https://gdk.test:3443/root',
                          webPath: '/root',
                          __typename: 'UserCore',
                        },
                        userPermissions: {
                          adminNote: false,
                          awardEmoji: true,
                          readNote: true,
                          createNote: true,
                          resolveNote: true,
                          repositionNote: false,
                          __typename: 'NotePermissions',
                        },
                        systemNoteMetadata: {
                          id: 'gid://gitlab/SystemNoteMetadata/704',
                          descriptionVersion: {
                            id: 'gid://gitlab/DescriptionVersion/199',
                            description: 'Desc2',
                            diff: '<span class="idiff">Desc</span><span class="idiff deletion">1</span><span class="idiff addition">2</span>',
                            diffPath: '/gnuwget/Wget2/-/issues/79/descriptions/199/diff',
                            deletePath: '/gnuwget/Wget2/-/issues/79/descriptions/199',
                            canDelete: true,
                            deleted: false,
                            __typename: 'DescriptionVersion',
                          },
                          __typename: 'SystemNoteMetadata',
                        },
                        awardEmoji: {
                          nodes: [],
                        },
                        __typename: 'Note',
                      },
                    ],
                    __typename: 'NoteConnection',
                  },
                  __typename: 'Discussion',
                },
                {
                  id: 'gid://gitlab/Discussion/391eed1ee0a258cc966a51dde900424f3b51b95d',
                  notes: {
                    nodes: [
                      {
                        id: 'gid://gitlab/Note/1689',
                        body: 'changed the description',
                        bodyHtml:
                          '<p data-sourcepos="1:1-1:23" dir="auto">changed the description</p>',
                        system: true,
                        internal: false,
                        systemNoteIconName: 'pencil',
                        createdAt: '2023-05-10T05:21:08Z',
                        lastEditedAt: '2023-05-10T05:21:08Z',
                        url: 'https://gdk.test:3443/gnuwget/Wget2/-/work_items/79#note_1689',
                        lastEditedBy: null,
                        maxAccessLevelOfAuthor: 'Owner',
                        authorIsContributor: false,
                        externalAuthor: null,
                        discussion: {
                          id: 'gid://gitlab/Discussion/391eed1ee0a258cc966a51dde900424f3b51b95d',
                          resolved: false,
                          resolvable: false,
                          resolvedBy: null,
                          __typename: 'Discussion',
                        },
                        author: {
                          id: 'gid://gitlab/User/1',
                          avatarUrl:
                            'https://secure.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                          name: 'Administrator',
                          username: 'root',
                          webUrl: 'https://gdk.test:3443/root',
                          webPath: '/root',
                          __typename: 'UserCore',
                        },
                        userPermissions: {
                          adminNote: false,
                          awardEmoji: true,
                          readNote: true,
                          createNote: true,
                          resolveNote: true,
                          repositionNote: false,
                          __typename: 'NotePermissions',
                        },
                        systemNoteMetadata: {
                          id: 'gid://gitlab/SystemNoteMetadata/705',
                          descriptionVersion: {
                            id: 'gid://gitlab/DescriptionVersion/200',
                            description: 'Desc3',
                            diff: '<span class="idiff">Desc</span><span class="idiff deletion">2</span><span class="idiff addition">3</span>',
                            diffPath: '/gnuwget/Wget2/-/issues/79/descriptions/200/diff',
                            deletePath: '/gnuwget/Wget2/-/issues/79/descriptions/200',
                            canDelete: true,
                            deleted: false,
                            __typename: 'DescriptionVersion',
                          },
                          __typename: 'SystemNoteMetadata',
                        },
                        awardEmoji: {
                          nodes: [],
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
          {
            __typename: 'WorkItemWidgetHealthStatus',
          },
          {
            __typename: 'WorkItemWidgetProgress',
          },
          {
            __typename: 'WorkItemWidgetNotifications',
          },
          {
            __typename: 'WorkItemWidgetCurrentUserTodos',
          },
          {
            __typename: 'WorkItemWidgetAwardEmoji',
          },
        ],
        __typename: 'WorkItem',
      },
      __typename: 'Project',
    },
  },
};

export const getAwardEmojiResponse = (toggledOn) => {
  return {
    data: {
      awardEmojiToggle: {
        errors: [],
        toggledOn,
      },
    },
  };
};

export const getTodosMutationResponse = (state) => {
  return {
    data: {
      todoMutation: {
        todo: {
          id: 'gid://gitlab/Todo/1',
          state,
        },
        errors: [],
      },
    },
  };
};

export const linkedWorkItemResponse = (options, errors = []) => {
  const response = workItemResponseFactory(options);
  return {
    data: {
      workItemAddLinkedItems: {
        workItem: response.data.workItem,
        errors,
        __typename: 'WorkItemAddLinkedItemsPayload',
      },
    },
  };
};

export const removeLinkedWorkItemResponse = (message, errors = []) => {
  return {
    data: {
      workItemRemoveLinkedItems: {
        errors,
        message,
        __typename: 'WorkItemRemoveLinkedItemsPayload',
      },
    },
  };
};

export const groupWorkItemStateCountsQueryResponse = {
  data: {
    group: {
      id: 'gid://gitlab/Group/3',
      workItemStateCounts: {
        all: 3,
        closed: 1,
        opened: 2,
      },
    },
  },
};

export const groupWorkItemsQueryResponse = {
  data: {
    group: {
      id: 'gid://gitlab/Group/3',
      name: 'Test',
      workItems: {
        pageInfo: {
          hasNextPage: true,
          hasPreviousPage: false,
          startCursor: 'startCursor',
          endCursor: 'endCursor',
          __typename: 'PageInfo',
        },
        nodes: [
          {
            id: 'gid://gitlab/WorkItem/58',
            iid: '23',
            author: {
              id: 'gid://gitlab/User/9',
              avatarUrl: 'author/avatar/url',
              name: 'Arthur',
              username: 'arthur',
              webUrl: 'author/web/url',
              webPath: 'author/web/url',
            },
            closedAt: '',
            confidential: true,
            createdAt: '2020-01-23T12:34:56Z',
            namespace: {
              id: 'full-path-epic-id',
              fullPath: 'full-path',
            },
            reference: 'javascriptjs/js#23',
            state: 'OPEN',
            title: 'a group level work item',
            updatedAt: '',
            webUrl: 'web/url',
            widgets: [
              {
                __typename: 'WorkItemWidgetAssignees',
                assignees: {
                  nodes: mockAssignees,
                },
                type: 'ASSIGNEES',
              },
              {
                __typename: 'WorkItemWidgetLabels',
                allowsScopedLabels: false,
                labels: {
                  nodes: [
                    {
                      __typename: 'Label',
                      id: 'gid://gitlab/Label/7',
                      color: '#f00',
                      description: '',
                      title: 'Label 7',
                    },
                  ],
                },
                type: 'LABELS',
              },
            ],
            workItemType: {
              id: 'gid://gitlab/WorkItems::Type/5',
              name: 'Issue',
            },
          },
        ],
      },
    },
  },
};

export const updateWorkItemMutationResponseFactory = (options) => {
  const response = workItemResponseFactory(options);
  return {
    data: {
      workItemUpdate: {
        workItem: response.data.workItem,
        errors: [],
      },
    },
  };
};

export const updateWorkItemNotificationsMutationResponse = (subscribed) => ({
  data: {
    workItemSubscribe: {
      workItem: {
        id: 'gid://gitlab/WorkItem/1',
        widgets: [
          {
            __typename: 'WorkItemWidgetNotifications',
            type: 'NOTIFICATIONS',
            subscribed,
          },
        ],
      },
      errors: [],
    },
  },
});

export const allowedChildrenTypesResponse = {
  data: {
    workItem: {
      id: 'gid://gitlab/WorkItem/634',
      workItemType: {
        id: 'gid://gitlab/WorkItems::Type/6',
        name: 'Objective',
        widgetDefinitions: [
          {
            type: 'HIERARCHY',
            allowedChildTypes: {
              nodes: [
                {
                  id: 'gid://gitlab/WorkItems::Type/7',
                  name: 'Key Result',
                  __typename: 'WorkItemType',
                },
                {
                  id: 'gid://gitlab/WorkItems::Type/6',
                  name: 'Objective',
                  __typename: 'WorkItemType',
                },
              ],
              __typename: 'WorkItemTypeConnection',
            },
            __typename: 'WorkItemWidgetDefinitionHierarchy',
          },
        ],
        __typename: 'WorkItemType',
      },
      __typename: 'WorkItem',
    },
  },
};

export const allowedParentTypesResponse = {
  data: {
    workItem: {
      id: 'gid://gitlab/WorkItem/1',
      workItemType: {
        id: 'gid://gitlab/WorkItems::Type/1',
        name: 'Issue',
        widgetDefinitions: [
          {
            type: 'HIERARCHY',
            allowedParentTypes: {
              nodes: [
                {
                  id: 'gid://gitlab/WorkItems::Type/8',
                  name: 'Epic',
                  __typename: 'WorkItemType',
                },
              ],
              __typename: 'WorkItemTypeConnection',
            },
            __typename: 'WorkItemWidgetDefinitionHierarchy',
          },
        ],
        __typename: 'WorkItemType',
      },
      __typename: 'WorkItem',
    },
  },
};

export const allowedParentTypesEmptyResponse = {
  data: {
    workItem: {
      id: 'gid://gitlab/WorkItem/1',
      workItemType: {
        id: 'gid://gitlab/WorkItems::Type/1',
        name: 'Issue',
        widgetDefinitions: [
          {
            type: 'HIERARCHY',
            allowedParentTypes: {
              nodes: [],
              __typename: 'WorkItemTypeConnection',
            },
            __typename: 'WorkItemWidgetDefinitionHierarchy',
          },
        ],
        __typename: 'WorkItemType',
      },
      __typename: 'WorkItem',
    },
  },
};

export const generateWorkItemsListWithId = (count) =>
  Array.from({ length: count }, (_, i) => ({ id: `gid://gitlab/WorkItem/${i + 1}` }));

export const namespaceProjectsList = {
  data: {
    namespace: {
      id: 'gid://gitlab/Group/1',
      projects: {
        nodes: [
          {
            id: 'gid://gitlab/Project/1',
            name: 'Example project A',
            avatarUrl: null,
            nameWithNamespace: 'Group A / Example project A',
            fullPath: 'group-a/example-project-a',
            namespace: {
              id: 'gid://gitlab/Group/1',
              name: 'Group A',
              __typename: 'Namespace',
            },
            __typename: 'Project',
          },
          {
            id: 'gid://gitlab/Project/2',
            name: 'Example project B',
            avatarUrl: null,
            nameWithNamespace: 'Group A / Example project B',
            fullPath: 'group-a/example-project-b',
            namespace: {
              id: 'gid://gitlab/Group/1',
              name: 'Group A',
              __typename: 'Namespace',
            },
            __typename: 'Project',
          },
          {
            id: 'gid://gitlab/Project/3',
            name: 'Example project C',
            avatarUrl: null,
            nameWithNamespace: 'Group A / Example project C',
            fullPath: 'group-a/example-project-c',
            namespace: {
              id: 'gid://gitlab/Group/1',
              name: 'Group A',
              __typename: 'Namespace',
            },
            __typename: 'Project',
          },
        ],
        __typename: 'ProjectConnection',
      },
      __typename: 'Group',
    },
  },
};

export const mockFrequentlyUsedProjects = [
  {
    id: 1,
    name: 'Example project B',
    namespace: 'Group A / Example project B',
    webUrl: '/group-a/example-project-b',
    avatarUrl: null,
    lastAccessedOn: 123,
    frequency: 4,
  },
  {
    id: 2,
    name: 'Example project A',
    namespace: 'Group A / Example project A',
    webUrl: '/group-a/example-project-a',
    avatarUrl: null,
    lastAccessedOn: 124,
    frequency: 3,
  },
];

export const namespaceGroupsList = {
  data: {
    group: {
      id: 'gid://gitlab/Group/33',
      name: 'Group A',
      avatarUrl: 'http://example.com/avatar-url',
      path: 'group-a',
      fullPath: 'group-a',
      descendantGroups: {
        nodes: [
          {
            id: 'gid://gitlab/Group/99',
            name: 'Group B',
            avatarUrl: null,
            path: 'group-b',
            fullPath: 'group-a/group-b',
            __typename: 'Group',
          },
          {
            id: 'gid://gitlab/Group/97',
            name: 'Group C',
            avatarUrl: null,
            path: 'group-c',
            fullPath: 'group-a/group-c',
            __typename: 'Group',
          },
        ],
        __typename: 'GroupConnection',
      },
      __typename: 'Group',
    },
  },
};

export const createWorkItemQueryResponse = {
  data: {
    workspace: {
      id: 'full-path-epic-id',
      workItem: {
        id: 'gid://gitlab/WorkItem/new-epic',
        iid: NEW_WORK_ITEM_IID,
        archived: false,
        title: '',
        state: 'OPEN',
        description: '',
        confidential: false,
        createdAt: '2024-05-09T05:57:05Z',
        updatedAt: '2024-05-09T09:35:32Z',
        closedAt: null,
        webUrl: 'http://127.0.0.1:3000/groups/gitlab-org/-/work_items/new',
        reference: 'gitlab-org#56',
        createNoteEmail: null,
        project: null,
        namespace: {
          id: 'full-path-epic-id',
          fullPath: 'full-path',
          name: 'Gitlab Org',
          fullName: 'Group name',
          __typename: 'Namespace',
        },
        author: {
          id: 'gid://gitlab/User/1',
          avatarUrl:
            'https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon',
          name: 'Administrator',
          username: 'root',
          webUrl: 'http://127.0.0.1:3000/root',
          webPath: '/root',
          __typename: 'UserCore',
        },
        workItemType: {
          id: 'gid://gitlab/WorkItems::Type/8',
          name: 'Epic',
          iconName: 'issue-type-epic',
          __typename: 'WorkItemType',
        },
        userPermissions: {
          deleteWorkItem: true,
          updateWorkItem: true,
          adminParentLink: true,
          setWorkItemMetadata: true,
          createNote: true,
          adminWorkItemLink: true,
          markNoteAsInternal: true,
          reportSpam: false,
          __typename: 'WorkItemPermissions',
        },
        mockWidgets: [],
        widgets: [
          {
            type: 'ASSIGNEES',
            allowsMultipleAssignees: true,
            canInviteMembers: false,
            assignees: {
              nodes: [],
              __typename: 'UserCoreConnection',
            },
            __typename: 'WorkItemWidgetAssignees',
          },
          {
            type: 'DESCRIPTION',
            description: '',
            descriptionHtml: '',
            lastEditedAt: '2024-05-09T05:57:04Z',
            lastEditedBy: {
              name: 'Administrator',
              webPath: '/root',
              __typename: 'UserCore',
            },
            taskCompletionStatus: {
              completedCount: 0,
              count: 4,
              __typename: 'TaskCompletionStatus',
            },
            __typename: 'WorkItemWidgetDescription',
          },
          {
            type: 'HIERARCHY',
            hasChildren: false,
            parent: null,
            hasParent: false,
            rolledUpCountsByType: [],
            children: {
              nodes: [],
              __typename: 'WorkItemConnection',
            },
            __typename: 'WorkItemWidgetHierarchy',
          },
          {
            type: 'LABELS',
            allowsScopedLabels: true,
            labels: {
              nodes: [],
              __typename: 'LabelConnection',
            },
            __typename: 'WorkItemWidgetLabels',
          },
          {
            type: 'NOTES',
            discussionLocked: null,
            __typename: 'WorkItemWidgetNotes',
          },
          {
            type: 'START_AND_DUE_DATE',
            dueDate: null,
            startDate: null,
            isFixed: null,
            rollUp: null,
            __typename: 'WorkItemWidgetStartAndDueDate',
          },
          {
            type: 'HEALTH_STATUS',
            healthStatus: null,
            rolledUpHealthStatus: [],
            __typename: 'WorkItemWidgetHealthStatus',
          },
          {
            type: 'STATUS',
            __typename: 'WorkItemWidgetStatus',
          },
          {
            type: 'NOTIFICATIONS',
            subscribed: true,
            __typename: 'WorkItemWidgetNotifications',
          },
          {
            type: 'AWARD_EMOJI',
            __typename: 'WorkItemWidgetAwardEmoji',
          },
          {
            type: 'LINKED_ITEMS',
            linkedItems: {
              nodes: [],
              __typename: 'LinkedWorkItemTypeConnection',
            },
            __typename: 'WorkItemWidgetLinkedItems',
          },
          {
            type: 'ITERATION',
            iteration: null,
            __typename: 'WorkItemWidgetIteration',
          },
          {
            type: 'MILESTONE',
            milestone: null,
            __typename: 'WorkItemWidgetMilestone',
          },
          {
            type: 'CURRENT_USER_TODOS',
            currentUserTodos: {
              nodes: [],
              __typename: 'TodoConnection',
            },
            __typename: 'WorkItemWidgetCurrentUserTodos',
          },
          {
            type: 'COLOR',
            color: '#1068bf', // default color in production
            textColor: '#1F1E24',
            __typename: 'WorkItemWidgetColor',
          },
          {
            type: 'PARTICIPANTS',
            participants: {
              nodes: [],
              __typename: 'UserCoreConnection',
            },
            __typename: 'WorkItemWidgetParticipants',
          },
          {
            type: 'TIME_TRACKING',
            timeEstimate: 0,
            timelogs: {
              nodes: [],
              __typename: 'WorkItemTimelogConnection',
            },
            totalTimeSpent: 0,
            __typename: 'WorkItemWidgetTimeTracking',
          },
          {
            type: 'CRM_CONTACTS',
            contacts: {
              nodes: [],
              __typename: 'CustomerRelationsContactConnection',
            },
            __typename: 'WorkItemWidgetCrmContacts',
          },
          {
            type: 'WEIGHT',
            weight: 2,
            rolledUpWeight: 0,
            rolledUpCompletedWeight: 0,
            widgetDefinition: {
              editable: true,
              rollUp: false,
              __typename: 'WorkItemWidgetDefinitionWeight',
            },
            __typename: 'WorkItemWidgetWeight',
          },
        ],
        __typename: 'WorkItem',
      },
      __typename: 'Namespace',
    },
  },
};

export const mockToggleResolveDiscussionResponse = {
  data: {
    discussionToggleResolve: {
      discussion: {
        id: 'gid://gitlab/Discussion/c4be5bec43a737e0966dbc4c040b1517e7febfa9',
        notes: {
          nodes: [
            {
              id: 'gid://gitlab/DiscussionNote/2506',
              body: 'test3',
              bodyHtml: '<p data-sourcepos="1:1-1:5" dir="auto">test3</p>',
              system: false,
              internal: false,
              systemNoteIconName: null,
              createdAt: '2024-07-19T05:52:01Z',
              lastEditedAt: '2024-07-26T10:06:02Z',
              url: 'http://127.0.0.1:3000/flightjs/Flight/-/issues/134#note_2506',
              authorIsContributor: false,
              maxAccessLevelOfAuthor: 'Owner',
              lastEditedBy: null,
              externalAuthor: null,
              discussion: {
                id: 'gid://gitlab/Discussion/c4be5bec43a737e0966dbc4c040b1517e7febfa9',
                resolved: true,
                resolvable: true,
                resolvedBy: {
                  id: 'gid://gitlab/User/1',
                  name: 'Administrator',
                  __typename: 'UserCore',
                },
                __typename: 'Discussion',
              },
              author: {
                id: 'gid://gitlab/User/1',
                avatarUrl:
                  'https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon',
                name: 'Administrator',
                username: 'root',
                webUrl: 'http://127.0.0.1:3000/root',
                webPath: '/root',
                __typename: 'UserCore',
              },
              awardEmoji: {
                nodes: [],
                __typename: 'AwardEmojiConnection',
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
              systemNoteMetadata: null,
              __typename: 'Note',
            },
            {
              id: 'gid://gitlab/DiscussionNote/2539',
              body: 'comment',
              bodyHtml: '<p data-sourcepos="1:1-1:7" dir="auto">comment</p>',
              system: false,
              internal: false,
              systemNoteIconName: null,
              createdAt: '2024-07-23T05:07:46Z',
              lastEditedAt: '2024-07-26T10:06:02Z',
              url: 'http://127.0.0.1:3000/flightjs/Flight/-/issues/134#note_2539',
              authorIsContributor: false,
              maxAccessLevelOfAuthor: 'Owner',
              lastEditedBy: null,
              externalAuthor: null,
              discussion: {
                id: 'gid://gitlab/Discussion/c4be5bec43a737e0966dbc4c040b1517e7febfa9',
                resolved: true,
                resolvable: true,
                resolvedBy: {
                  id: 'gid://gitlab/User/1',
                  name: 'Administrator',
                  __typename: 'UserCore',
                },
                __typename: 'Discussion',
              },
              author: {
                id: 'gid://gitlab/User/1',
                avatarUrl:
                  'https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon',
                name: 'Administrator',
                username: 'root',
                webUrl: 'http://127.0.0.1:3000/root',
                webPath: '/root',
                __typename: 'UserCore',
              },
              awardEmoji: {
                nodes: [],
                __typename: 'AwardEmojiConnection',
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
              systemNoteMetadata: null,
              __typename: 'Note',
            },
          ],
          __typename: 'NoteConnection',
        },
        __typename: 'Discussion',
      },
      errors: [],
      __typename: 'DiscussionToggleResolvePayload',
    },
  },
};

const mockUserPermissions = {
  deleteWorkItem: true,
  updateWorkItem: true,
  adminParentLin: true,
  setWorkItemMetadata: true,
  createNote: true,
  adminWorkItemLink: true,
  markNoteAsInternal: true,
  reportSpam: false,
  __typename: 'WorkItemPermissions',
};

export const mockMoveWorkItemMutationResponse = ({ error = undefined } = {}) => ({
  data: {
    workItemsHierarchyReorder: {
      workItem: {
        id: 'gid://gitlab/WorkItem/6',
        workItemType: objectiveType,
        title: 'Objective 18',
        confidential: false,
        userPermissions: mockUserPermissions,
      },
      parentWorkItem: {
        id: 'gid://gitlab/WorkItem/5',
        workItemType: objectiveType,
        title: 'Objective 19',
        confidential: false,
        userPermissions: mockUserPermissions,
      },
      errors: [error],
    },
  },
});

export const mockUserPreferences = (useWorkItemsView = true) => ({
  data: {
    currentUser: {
      id: '1',
      userPreferences: {
        useWorkItemsView,
      },
    },
  },
});

export const mockProjectPermissionsQueryResponse = ({
  createDesign = true,
  moveDesign = true,
} = {}) => ({
  data: {
    workspace: {
      id: 'gid://gitlab/Project/1',
      userPermissions: {
        createDesign,
        moveDesign,
        __typename: 'ProjectPermissions',
      },
      __typename: 'Project',
    },
  },
});

export const mockUploadDesignMutationResponse = {
  data: {
    designManagementUpload: {
      designs: [
        {
          id: 'gid://gitlab/DesignManagement::Design/10',
          event: 'CREATION',
          filename: 'Screenshot_2024-09-16_at_12.08.41_PM.png',
          notesCount: 0,
          image:
            'http://127.0.0.1:3000/gitlab-org/gitlab-shell/-/design_management/designs/10/316e83ef399ac9ec00250426f7e2ae01fffa8133/raw_image',
          imageV432x230: null,
          description: null,
          descriptionHtml: '',
          fullPath: 'designs/issue-41/Screenshot_2024-09-16_at_12.08.41_PM.png',
          currentUserTodos: {
            nodes: [],
            __typename: 'TodoConnection',
          },
          __typename: 'Design',
          imported: false,
          diffRefs: {
            baseSha: '2ac26f2354eb7f4a18f69db273017393f41bd840',
            startSha: '2ac26f2354eb7f4a18f69db273017393f41bd840',
            headSha: '316e83ef399ac9ec00250426f7e2ae01fffa8133',
            __typename: 'DiffRefs',
          },
          discussions: {
            nodes: [],
            __typename: 'DiscussionConnection',
          },
          versions: {
            nodes: [
              {
                id: 'gid://gitlab/DesignManagement::Version/10',
                sha: '316e83ef399ac9ec00250426f7e2ae01fffa8133',
                createdAt: '2024-09-16T23:33:27Z',
                author: {
                  id: 'gid://gitlab/User/1',
                  name: 'Administrator',
                  avatarUrl:
                    'https://www.gravatar.com/avatar/f7da9a67cfc0e7a1927ea66dd241a7a31e1df50bb91b0fcd8f6d5fb20fb2f4c3?s=80&d=identicon',
                  __typename: 'UserCore',
                },
                __typename: 'DesignVersion',
              },
            ],
            __typename: 'DesignVersionConnection',
          },
        },
      ],
      skippedDesigns: [],
      errors: [],
      __typename: 'DesignManagementUploadPayload',
    },
  },
};

export const mockUploadSkippedDesignMutationResponse = {
  data: {
    designManagementUpload: {
      designs: [],
      skippedDesigns: [
        {
          id: 'gid://gitlab/DesignManagement::Design/14',
          filename: 'Version_test_1.png',
          __typename: 'Design',
        },
      ],
      errors: [],
      __typename: 'DesignManagementUploadPayload',
    },
  },
};

export const mockUploadErrorDesignMutationResponse = {
  errors: [
    {
      message:
        "The resource that you are attempting to access does not exist or you don't have permission to perform this action",
    },
  ],
  data: {
    designManagementUpload: null,
  },
};

export const workItemHierarchyNoChildrenTreeResponse = {
  data: {
    workItem: {
      id: 'gid://gitlab/WorkItem/3',
      iid: '3',
      archived: false,
      workItemType: {
        id: 'gid://gitlab/WorkItems::Type/2411',
        name: 'Objective',
        iconName: 'issue-type-objective',
        __typename: 'WorkItemType',
      },
      title: 'New title without children',
      userPermissions: {
        deleteWorkItem: true,
        updateWorkItem: true,
        setWorkItemMetadata: true,
        adminParentLink: true,
        createNote: true,
        adminWorkItemLink: true,
        markNoteAsInternal: true,
        reportSpam: false,
        __typename: 'WorkItemPermissions',
      },
      confidential: false,
      reference: 'test-project-path#2',
      namespace: {
        __typename: 'Project',
        id: '1',
        fullPath: 'test-project-path',
        name: 'Project name',
        fullName: 'Project name',
      },
      widgets: [
        {
          type: 'DESCRIPTION',
          __typename: 'WorkItemWidgetDescription',
        },
        {
          type: 'HIERARCHY',
          parent: null,
          hasChildren: false,
          depthLimitReachedByType: [],
          rolledUpCountsByType: [],
          children: {
            pageInfo: {
              hasNextPage: false,
              hasPreviousPage: false,
              startCursor: null,
              endCursor: null,
              __typename: 'PageInfo',
            },
            count: 0,
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

export const workItemEmailParticipantsResponse = {
  data: {
    workspace: {
      id: 'gid://gitlab/Namespaces::ProjectNamespace/34',
      workItem: {
        id: 'gid://gitlab/WorkItem/689',
        iid: '68',
        widgets: [
          {
            type: 'EMAIL_PARTICIPANTS',
            emailParticipants: {
              nodes: [
                {
                  email: 'user@example.com',
                  __typename: 'EmailParticipantType',
                },
              ],
              __typename: 'EmailParticipantTypeConnection',
            },
            __typename: 'WorkItemWidgetEmailParticipants',
          },
        ],
        __typename: 'WorkItem',
      },
      __typename: 'Namespace',
    },
  },
};

export const workItemEmailParticipantsEmptyResponse = {
  data: {
    workspace: {
      id: 'gid://gitlab/Namespaces::ProjectNamespace/34',
      workItem: {
        id: 'gid://gitlab/WorkItem/689',
        iid: '68',
        widgets: [
          {
            type: 'EMAIL_PARTICIPANTS',
            emailParticipants: {
              nodes: [],
              __typename: 'EmailParticipantTypeConnection',
            },
            __typename: 'WorkItemWidgetEmailParticipants',
          },
        ],
        __typename: 'WorkItem',
      },
      __typename: 'Namespace',
    },
  },
};
