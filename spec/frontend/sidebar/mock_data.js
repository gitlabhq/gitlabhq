import { userTypes } from '~/sidebar/components/assignees/constants';

export const createMockUser = (userDetails) => {
  return {
    __typename: 'UserCore',
    status: null,
    canMerge: false,
    ...userDetails,
  };
};

export const mockUser1 = createMockUser({
  id: 'gid://gitlab/User/1',
  avatarUrl:
    'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
  name: 'Administrator',
  username: 'root',
  webUrl: '/root',
  webPath: '/root',
});

export const mockUserWithType1 = {
  ...mockUser1,
  type: userTypes.human,
};

export const mockUser2 = createMockUser({
  id: 'gid://gitlab/User/5',
  avatarUrl: '/avatar2',
  name: 'rookie',
  username: 'rookie',
  webUrl: 'rookie',
  webPath: '/rookie',
});

export const mockUserWithType2 = {
  ...mockUser2,
  type: userTypes.human,
};

export const placeholderAuthor = {
  id: 'some-placeholder-user',
  type: userTypes.placeholder,
  avatarUrl: '/avatar',
  status: null,
  name: 'PlaceholderRoot',
  username: 'placeholder_root_1',
  webUrl: '/placeholder_user_1',
  webPath: '/placeholder_user_1',
};

export const initialAssignees = [mockUserWithType2];

export const initialAssigneesPlaceholder = [placeholderAuthor];

const RESPONSE_MAP = {
  GET: {
    '/gitlab-org/gitlab-shell/issues/5.json': {
      id: 45,
      iid: 5,
      author_id: 23,
      description: 'Nulla ullam commodi delectus adipisci quis sit.',
      lock_version: null,
      milestone_id: 21,
      position: 0,
      state: 'closed',
      title: 'Vel et nulla voluptatibus corporis dolor iste saepe laborum.',
      updated_by_id: 1,
      created_at: '2017-02-02T21: 49: 49.664Z',
      updated_at: '2017-05-03T22: 26: 03.760Z',
      time_estimate: 0,
      total_time_spent: 0,
      human_time_estimate: null,
      human_total_time_spent: null,
      branch_name: null,
      confidential: false,
      assignees: [
        {
          name: 'User 0',
          username: 'user0',
          id: 22,
          state: 'active',
          avatar_url:
            'https://www.gravatar.com/avatar/52e4ce24a915fb7e51e1ad3b57f4b00a?s=80\u0026d=identicon',
          web_url: 'http: //localhost:3001/user0',
          type: userTypes.human,
        },
        {
          name: 'Marguerite Bartell',
          username: 'tajuana',
          id: 18,
          state: 'active',
          avatar_url:
            'https://www.gravatar.com/avatar/4852a41fb41616bf8f140d3701673f53?s=80\u0026d=identicon',
          web_url: 'http: //localhost:3001/tajuana',
          type: userTypes.human,
        },
        {
          name: 'Laureen Ritchie',
          username: 'michaele.will',
          id: 16,
          state: 'active',
          avatar_url:
            'https://www.gravatar.com/avatar/e301827eb03be955c9c172cb9a8e4e8a?s=80\u0026d=identicon',
          web_url: 'http: //localhost:3001/michaele.will',
          type: userTypes.service_user,
        },
      ],
      due_date: null,
      moved_to_id: null,
      project_id: 4,
      weight: null,
      milestone: {
        id: 21,
        iid: 1,
        project_id: 4,
        title: 'v0.0',
        description: 'Molestiae commodi laboriosam odio sunt eaque reprehenderit.',
        state: 'active',
        created_at: '2017-02-02T21: 49: 30.530Z',
        updated_at: '2017-02-02T21: 49: 30.530Z',
        due_date: null,
        start_date: null,
      },
      labels: [],
    },
    '/gitlab-org/gitlab-shell/issues/5.json?serializer=sidebar_extras': {
      assignees: [
        {
          name: 'User 0',
          username: 'user0',
          id: 22,
          state: 'active',
          avatar_url:
            'https://www.gravatar.com/avatar/52e4ce24a915fb7e51e1ad3b57f4b00a?s=80\u0026d=identicon',
          web_url: 'http://localhost:3001/user0',
          type: userTypes.human,
        },
        {
          name: 'Marguerite Bartell',
          username: 'tajuana',
          id: 18,
          state: 'active',
          avatar_url:
            'https://www.gravatar.com/avatar/4852a41fb41616bf8f140d3701673f53?s=80\u0026d=identicon',
          web_url: 'http://localhost:3001/tajuana',
          type: userTypes.human,
        },
        {
          name: 'Laureen Ritchie',
          username: 'michaele.will',
          id: 16,
          state: 'active',
          avatar_url:
            'https://www.gravatar.com/avatar/e301827eb03be955c9c172cb9a8e4e8a?s=80\u0026d=identicon',
          web_url: 'http://localhost:3001/michaele.will',
          type: userTypes.service_user,
        },
      ],
      human_time_estimate: null,
      human_total_time_spent: null,
      participants: [
        {
          name: 'User 0',
          username: 'user0',
          id: 22,
          state: 'active',
          avatar_url:
            'https://www.gravatar.com/avatar/52e4ce24a915fb7e51e1ad3b57f4b00a?s=80\u0026d=identicon',
          web_url: 'http://localhost:3001/user0',
          type: userTypes.human,
        },
        {
          name: 'Marguerite Bartell',
          username: 'tajuana',
          id: 18,
          state: 'active',
          avatar_url:
            'https://www.gravatar.com/avatar/4852a41fb41616bf8f140d3701673f53?s=80\u0026d=identicon',
          web_url: 'http://localhost:3001/tajuana',
          type: userTypes.human,
        },
        {
          name: 'Laureen Ritchie',
          username: 'michaele.will',
          id: 16,
          state: 'active',
          avatar_url:
            'https://www.gravatar.com/avatar/e301827eb03be955c9c172cb9a8e4e8a?s=80\u0026d=identicon',
          web_url: 'http://localhost:3001/michaele.will',
          type: userTypes.service_user,
        },
      ],
      subscribed: true,
      time_estimate: 0,
      total_time_spent: 0,
    },
    '/autocomplete/projects?project_id=15': [
      {
        id: 0,
        name_with_namespace: 'No project',
      },
      {
        id: 20,
        name_with_namespace: '<img src=x onerror=alert(document.domain)> foo / bar',
      },
    ],
  },
  PUT: {
    '/gitlab-org/gitlab-shell/issues/5.json': {
      data: {},
    },
  },
  POST: {
    '/gitlab-org/gitlab-shell/issues/5/move': {
      id: 123,
      iid: 5,
      author_id: 1,
      description: 'some description',
      lock_version: 5,
      milestone_id: null,
      state: 'opened',
      title: 'some title',
      updated_by_id: 1,
      created_at: '2017-06-27T19:54:42.437Z',
      updated_at: '2017-08-18T03:39:49.222Z',
      time_estimate: 0,
      total_time_spent: 0,
      human_time_estimate: null,
      human_total_time_spent: null,
      branch_name: null,
      confidential: false,
      assignees: [],
      due_date: null,
      moved_to_id: null,
      project_id: 7,
      milestone: null,
      labels: [],
      web_url: '/root/some-project/issues/5',
    },
    '/gitlab-org/gitlab-shell/issues/5/toggle_subscription': {},
  },
};

const graphQlResponseData = {
  project: {
    issue: {
      healthStatus: 'onTrack',
    },
  },
};

const mockData = {
  responseMap: RESPONSE_MAP,
  graphQlResponseData,
  mediator: {
    endpoint: '/gitlab-org/gitlab-shell/issues/5.json?serializer=sidebar_extras',
    toggleSubscriptionEndpoint: '/gitlab-org/gitlab-shell/issues/5/toggle_subscription',
    moveIssueEndpoint: '/gitlab-org/gitlab-shell/issues/5/move',
    projectsAutocompleteEndpoint: '/autocomplete/projects?project_id=15',
    editable: true,
    currentUser: {
      id: 1,
      name: 'Administrator',
      username: 'root',
      avatar_url:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
      type: userTypes.human,
    },
    rootPath: '/',
    fullPath: '/gitlab-org/gitlab-shell',
    iid: 1,
  },
  time: {
    time_estimate: 3600,
    total_time_spent: 0,
    human_time_estimate: '1h',
    human_total_time_spent: null,
  },
  user: {
    avatar: 'https://gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
    id: 1,
    name: 'Administrator',
    username: 'root',
    type: userTypes.human,
  },
};

export const issueConfidentialityResponse = (confidential = false) => ({
  data: {
    workspace: {
      id: '1',
      __typename: 'Project',
      issuable: {
        __typename: 'Issue',
        id: 'gid://gitlab/Issue/4',
        confidential,
      },
    },
  },
});

export const issuableDueDateResponse = (dueDate = null) => ({
  data: {
    workspace: {
      id: '1',
      __typename: 'Project',
      issuable: {
        __typename: 'Issue',
        id: 'gid://gitlab/Issue/4',
        dueDate,
        dueDateFixed: dueDate,
      },
    },
  },
});

export const issueDueDateSubscriptionResponse = () => ({
  data: {
    issuableDatesUpdated: {
      issue: {
        id: 'gid://gitlab/Issue/4',
        dueDate: '2022-12-31',
      },
    },
  },
});

export const issuableStartDateResponse = (startDate = null) => ({
  data: {
    workspace: {
      id: '1',
      __typename: 'Group',
      issuable: {
        __typename: 'Epic',
        id: 'gid://gitlab/Epic/4',
        startDate,
        startDateIsFixed: true,
        startDateFixed: startDate,
        startDateFromMilestones: null,
      },
    },
  },
});

export const epicParticipantsResponse = () => ({
  data: {
    workspace: {
      id: '1',
      __typename: 'Group',
      issuable: {
        __typename: 'Epic',
        id: 'gid://gitlab/Epic/4',
        participants: {
          nodes: [
            {
              __typename: 'UserCore',
              id: 'gid://gitlab/User/2',
              avatarUrl:
                'https://www.gravatar.com/avatar/a95e5b71488f4b9d69ce5ff58bfd28d6?s=80\u0026d=identicon',
              name: 'Jacki Kub',
              username: 'francina.skiles',
              webUrl: '/franc',
              webPath: '/franc',
            },
          ],
        },
      },
    },
  },
});

export const issueReferenceResponse = (reference) => ({
  data: {
    workspace: {
      id: '1',
      __typename: 'Project',
      issuable: {
        __typename: 'Issue',
        id: 'gid://gitlab/Issue/4',
        reference,
      },
    },
  },
});

export const issueSubscriptionsResponse = (subscribed = false, emailsDisabled = false) => ({
  data: {
    workspace: {
      id: '1',
      __typename: 'Project',
      issuable: {
        __typename: 'Issue',
        id: 'gid://gitlab/Issue/4',
        subscribed,
        emailsDisabled,
      },
    },
  },
});

export const mergeRequestSubscriptionMutationResponse = {
  data: {
    updateIssuableSubscription: {
      issuable: {
        __typename: 'MergeRequest',
        id: 'gid://gitlab/MergeRequest/4',
        subscribed: true,
      },
      errors: [],
    },
  },
};

export const issuableQueryResponse = {
  data: {
    workspace: {
      __typename: 'Project',
      id: '1',
      issuable: {
        __typename: 'Issue',
        id: 'gid://gitlab/Issue/1',
        iid: '1',
        author: {
          id: '1',
          avatarUrl: '/avatar',
          name: 'root',
          username: 'root',
          webUrl: 'root',
          webPath: '/root',
          status: null,
          type: userTypes.human,
        },
        assignees: {
          nodes: [
            {
              __typename: 'UserCore',
              id: 'gid://gitlab/User/2',
              avatarUrl:
                'https://www.gravatar.com/avatar/a95e5b71488f4b9d69ce5ff58bfd28d6?s=80\u0026d=identicon',
              name: 'Jacki Kub',
              username: 'francina.skiles',
              webUrl: '/franc',
              webPath: '/franc',
              status: null,
              type: userTypes.human,
            },
          ],
        },
      },
    },
  },
};

export const issuableQueryWithPlaceholderResponse = {
  data: {
    workspace: {
      __typename: 'Project',
      id: '1',
      issuable: {
        __typename: 'Issue',
        id: 'gid://gitlab/Issue/1',
        iid: '1',
        author: {
          ...placeholderAuthor,
          id: '1',
          status: null,
        },
        assignees: {
          nodes: [
            {
              __typename: 'UserCore',
              id: 'gid://gitlab/User/1',
              ...placeholderAuthor,
            },
          ],
        },
      },
    },
  },
};

export const searchQueryResponse = {
  data: {
    workspace: {
      __typename: 'Project',
      id: '1',
      users: {
        nodes: [
          {
            user: {
              id: '1',
              avatarUrl: '/avatar',
              name: 'root',
              username: 'root',
              webUrl: 'root',
              webPath: '/root',
              status: null,
            },
          },
          {
            user: {
              id: '2',
              avatarUrl: '/avatar2',
              name: 'rookie',
              username: 'rookie',
              webUrl: 'rookie',
              webPath: '/rookie',
              status: null,
            },
          },
        ],
      },
    },
  },
};

export const searchAutocompleteQueryResponse = {
  data: {
    workspace: {
      __typename: 'Project',
      id: '',
      users: [
        {
          id: '1',
          avatarUrl: '/avatar',
          name: 'root',
          username: 'root',
          webUrl: 'root',
          webPath: '/root',
          status: null,
        },
        {
          id: '2',
          avatarUrl: '/avatar2',
          name: 'rookie',
          username: 'rookie',
          webUrl: 'rookie',
          webPath: '/rookie',
          status: null,
        },
      ],
    },
  },
};

export const updateIssueAssigneesMutationResponse = {
  data: {
    issuableSetAssignees: {
      issuable: {
        id: 'gid://gitlab/Issue/1',
        iid: '1',
        assignees: {
          nodes: [
            {
              __typename: 'UserCore',
              id: 'gid://gitlab/User/1',
              avatarUrl:
                'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
              name: 'Administrator',
              username: 'root',
              webUrl: '/root',
              webPath: '/root',
              status: null,
              type: userTypes.human,
            },
          ],
          __typename: 'UserConnection',
        },
        __typename: 'Issue',
      },
    },
  },
};

export const subscriptionNullResponse = {
  data: {
    issuableAssigneesUpdated: null,
  },
};

export const subscriptionResponse = {
  data: {
    issuableAssigneesUpdated: {
      id: '1',
      assignees: {
        nodes: [
          {
            __typename: 'UserCore',
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
  },
};

export const searchResponse = {
  data: {
    workspace: {
      __typename: 'Project',
      id: '1',
      users: {
        nodes: [
          {
            id: 'gid://gitlab/User/1',
            user: mockUser1,
          },
          {
            id: 'gid://gitlab/User/4',
            user: mockUser2,
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

export const searchResponseOnMR = {
  data: {
    workspace: {
      __typename: 'Project',
      id: '1',
      users: {
        nodes: [
          {
            id: 'gid://gitlab/User/1',
            user: mockUser1,
            mergeRequestInteraction: {
              canMerge: true,
            },
          },
          {
            id: 'gid://gitlab/User/4',
            user: mockUser2,
            mergeRequestInteraction: {
              canMerge: false,
            },
          },
        ],
      },
    },
  },
};

export const searchAutocompleteResponseOnMR = {
  data: {
    workspace: {
      __typename: 'Project',
      id: '1',
      users: [
        {
          ...mockUser1,
          mergeRequestInteraction: {
            canMerge: true,
          },
        },
        {
          ...mockUser2,
          mergeRequestInteraction: {
            canMerge: false,
          },
        },
      ],
    },
  },
};

export const projectMembersResponse = {
  data: {
    project: {
      id: '1',
      __typename: 'Project',
      autocompleteUsers: [
        mockUser1,
        mockUser2,
        {
          __typename: 'UserCore',
          id: 'gid://gitlab/User/2',
          avatarUrl:
            'https://www.gravatar.com/avatar/a95e5b71488f4b9d69ce5ff58bfd28d6?s=80\u0026d=identicon',
          name: 'Jacki Kub',
          username: 'francina.skiles',
          webUrl: '/franc',
          webPath: '/franc',
          status: {
            availability: 'BUSY',
          },
        },
      ],
    },
  },
};

export const projectAutocompleteMembersResponse = {
  data: {
    workspace: {
      id: '1',
      __typename: 'Project',
      users: [
        // Remove nulls https://gitlab.com/gitlab-org/gitlab/-/issues/329750
        null,
        null,
        // Remove duplicated entry https://gitlab.com/gitlab-org/gitlab/-/issues/327822
        mockUser1,
        mockUser1,
        mockUser2,
        {
          __typename: 'UserCore',
          id: 'gid://gitlab/User/2',
          avatarUrl:
            'https://www.gravatar.com/avatar/a95e5b71488f4b9d69ce5ff58bfd28d6?s=80\u0026d=identicon',
          name: 'Jacki Kub',
          username: 'francina.skiles',
          webUrl: '/franc',
          webPath: '/franc',
          status: {
            availability: 'BUSY',
          },
        },
      ],
    },
  },
};

export const groupMembersResponse = {
  data: {
    group: {
      id: '1',
      __typename: 'Group',
      autocompleteUsers: [
        mockUser1,
        {
          __typename: 'UserCore',
          id: 'gid://gitlab/User/2',
          avatarUrl:
            'https://www.gravatar.com/avatar/a95e5b71488f4b9d69ce5ff58bfd28d6?s=80\u0026d=identicon',
          name: 'Jacki Kub',
          username: 'francina.skiles',
          webUrl: '/franc',
          webPath: '/franc',
          status: {
            availability: 'BUSY',
          },
        },
      ],
    },
  },
};

export const participantsQueryResponse = {
  data: {
    workspace: {
      __typename: 'Project',
      id: '1',
      issuable: {
        __typename: 'Issue',
        id: 'gid://gitlab/Issue/1',
        iid: '1',
        participants: {
          nodes: [
            // Remove duplicated entry https://gitlab.com/gitlab-org/gitlab/-/issues/327822
            mockUser1,
            mockUser1,
            {
              __typename: 'UserCore',
              id: 'gid://gitlab/User/2',
              avatarUrl:
                'https://www.gravatar.com/avatar/a95e5b71488f4b9d69ce5ff58bfd28d6?s=80\u0026d=identicon',
              name: 'Jacki Kub',
              username: 'francina.skiles',
              webUrl: '/franc',
              webPath: '/franc',
              status: {
                availability: 'BUSY',
              },
            },
            {
              __typename: 'UserCore',
              id: 'gid://gitlab/User/3',
              avatarUrl: '/avatar',
              name: 'John Doe',
              username: 'rollie',
              webUrl: '/john',
              webPath: '/john',
              status: null,
            },
          ],
        },
      },
    },
  },
};

export const mrAssigneesQueryResponse = {
  data: {
    workspace: {
      __typename: 'Project',
      id: '1',
      issuable: {
        __typename: 'MergeRequest',
        id: 'gid://gitlab/MergeRequest/1',
        iid: '1',
        author: {
          id: '1',
          avatarUrl: '/avatar',
          name: 'root',
          username: 'root',
          webUrl: 'root',
          webPath: '/root',
          status: null,
          type: userTypes.human,
          mergeRequestInteraction: {
            canMerge: true,
          },
        },
        assignees: {
          nodes: [],
        },
        userPermissions: {
          canMerge: true,
        },
      },
    },
  },
};

export const mockGroupPath = 'gitlab-org';
export const mockProjectPath = `${mockGroupPath}/some-project`;

export const mockIssue = {
  projectPath: mockProjectPath,
  iid: '1',
  groupPath: mockGroupPath,
};

export const mockIssueId = 'gid://gitlab/Issue/1';

export const mockMilestone1 = {
  __typename: 'Milestone',
  id: 'gid://gitlab/Milestone/1',
  title: 'Foobar Milestone',
  webUrl: 'http://gdk.test:3000/groups/gitlab-org/-/milestones/1',
  state: 'active',
  expired: false,
  dueDate: '2030-09-09',
};

export const mockMilestone2 = {
  __typename: 'Milestone',
  id: 'gid://gitlab/Milestone/2',
  title: 'Awesome Milestone',
  webUrl: 'http://gdk.test:3000/groups/gitlab-org/-/milestones/2',
  state: 'active',
  expired: false,
  dueDate: '2030-09-09',
};

export const mockProjectMilestonesResponse = {
  data: {
    workspace: {
      id: 'gid://gitlab/Project/1',
      attributes: {
        nodes: [mockMilestone1, mockMilestone2],
      },
      __typename: 'MilestoneConnection',
    },
    __typename: 'Project',
  },
};

export const mockGroupMilestonesResponse = {
  data: {
    workspace: {
      id: 'gid://gitlab/Group/1',
      attributes: {
        nodes: [mockMilestone1, mockMilestone2],
      },
      __typename: 'MilestoneConnection',
    },
    __typename: 'Group',
  },
};

export const noCurrentMilestoneResponse = {
  data: {
    workspace: {
      issuable: { id: mockIssueId, attribute: null, __typename: 'Issue' },
      __typename: 'Project',
    },
  },
};

export const mockMilestoneMutationResponse = {
  data: {
    issuableSetAttribute: {
      errors: [],
      issuable: {
        id: 'gid://gitlab/Issue/1',
        attribute: {
          id: 'gid://gitlab/Milestone/2',
          title: 'Awesome Milestone',
          state: 'active',
          expired: false,
          dueDate: '2030-09-09',
          __typename: 'Milestone',
        },
        __typename: 'Issue',
      },
      __typename: 'UpdateIssuePayload',
    },
  },
};

export const emptyProjectMilestonesResponse = {
  data: {
    workspace: {
      attributes: {
        nodes: [],
      },
      __typename: 'MilestoneConnection',
    },
    __typename: 'Project',
  },
};

export const issuableTimeTrackingResponse = {
  data: {
    workspace: {
      __typename: 'Project',
      issuable: {
        __typename: 'Issue',
        id: 'gid://gitlab/Issue/1',
        title: 'Commodi incidunt eos eos libero dicta dolores sed.',
        timeEstimate: 10_000, // 2h 46m
        totalTimeSpent: 5_000, // 1h 23m
        humanTimeEstimate: '2h 46m',
        humanTotalTimeSpent: '1h 23m',
      },
    },
  },
};

export const todosResponse = {
  data: {
    workspace: {
      __typename: 'Group',
      id: '1',
      issuable: {
        __typename: 'Epic',
        id: 'gid://gitlab/Epic/4',
        currentUserTodos: {
          nodes: [
            {
              id: 'gid://gitlab/Todo/433',
            },
          ],
        },
      },
    },
  },
};

export const noMergeRequestTodosResponse = {
  data: {
    workspace: {
      id: '1',
      __typename: 'Project',
      issuable: {
        __typename: 'MergeRequest',
        id: 'gid://gitlab/MergeRequest/1',
        currentUserTodos: {
          nodes: [],
        },
      },
    },
  },
};

export const noTodosResponse = {
  data: {
    workspace: {
      id: '1',
      __typename: 'Group',
      issuable: {
        __typename: 'Epic',
        id: 'gid://gitlab/Epic/4',
        currentUserTodos: {
          nodes: [],
        },
      },
    },
  },
};

export default mockData;
