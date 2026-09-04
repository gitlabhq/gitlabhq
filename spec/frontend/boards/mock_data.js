import { GlFilteredSearchToken } from '@gitlab/ui';
import { keyBy } from 'lodash-es';
import {
  OPTIONS_NONE_ANY,
  OPTIONS_NONE_ANY_ME,
  OPERATORS_IS,
  OPERATORS_IS_NOT,
  TOKEN_TITLE_ASSIGNEE,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_CONFIDENTIAL,
  TOKEN_TITLE_LABEL,
  TOKEN_TITLE_MILESTONE,
  TOKEN_TITLE_MY_REACTION,
  TOKEN_TITLE_RELEASE,
  TOKEN_TITLE_TYPE,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_TYPE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import UserToken from '~/vue_shared/components/filtered_search_bar/tokens/user_token.vue';
import EmojiToken from '~/vue_shared/components/filtered_search_bar/tokens/emoji_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';
import MilestoneToken from '~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue';
import ReleaseToken from '~/vue_shared/components/filtered_search_bar/tokens/release_token.vue';
import WorkItemTypeToken from '~/vue_shared/components/filtered_search_bar/tokens/work_item_type_token.vue';

export const mockBoard = {
  milestone: {
    id: 'gid://gitlab/Milestone/114',
    title: '14.9',
  },
  iteration: {
    id: 'gid://gitlab/Iteration/124',
    title: 'Iteration 9',
  },
  iterationCadence: {
    id: 'gid://gitlab/Iteration::Cadence/134',
    title: 'Cadence 3',
  },
  assignee: {
    id: 'gid://gitlab/User/1',
    username: 'admin',
  },
  labels: {
    nodes: [{ id: 'gid://gitlab/Label/32', title: 'Deliverable' }],
  },
  weight: 2,
};

export const mockProjectBoardResponse = {
  data: {
    namespace: {
      id: 'gid://gitlab/Project/114',
      board: mockBoard,
      __typename: 'Project',
    },
  },
};

export const mockGroupBoardResponse = {
  data: {
    namespace: {
      id: 'gid://gitlab/Group/114',
      board: mockBoard,
      __typename: 'Group',
    },
  },
};

export const boardObj = {
  id: 1,
  name: 'test',
  milestone_id: null,
  labels: [],
};

export const listObj = {
  id: 300,
  position: 0,
  title: 'Test',
  list_type: 'label',
  label: {
    id: 5000,
    title: 'Test',
    color: '#ff0000',
    description: 'testing;',
    textColor: 'white',
  },
};

function boardGenerator(n) {
  return new Array(n).fill().map((board, index) => {
    const id = `${index}`;
    const name = `board${id}`;

    return {
      id,
      name,
      weight: 0,
      __typename: 'Board',
    };
  });
}

export const boards = boardGenerator(20);
export const recentIssueBoards = boardGenerator(5);

export const mockSmallProjectAllBoardsResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/114',
      boards: { nodes: boardGenerator(3) },
      __typename: 'Project',
    },
  },
};

export const mockEmptyProjectRecentBoardsResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/114',
      recentIssueBoards: { nodes: [] },
      __typename: 'Project',
    },
  },
};

export const mockGroupAllBoardsResponse = {
  data: {
    group: {
      id: 'gid://gitlab/Group/114',
      boards: { nodes: boards },
      __typename: 'Group',
    },
  },
};

export const mockProjectAllBoardsResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      boards: { nodes: boards },
      __typename: 'Project',
    },
  },
};

export const mockGroupRecentBoardsResponse = {
  data: {
    group: {
      id: 'gid://gitlab/Group/114',
      recentIssueBoards: { nodes: recentIssueBoards },
      __typename: 'Group',
    },
  },
};

export const mockProjectRecentBoardsResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      recentIssueBoards: { nodes: recentIssueBoards },
      __typename: 'Project',
    },
  },
};

export const mockAssigneesList = [
  {
    id: 2,
    name: 'Terrell Graham',
    username: 'monserrate.gleichner',
    state: 'active',
    avatar_url: 'https://www.gravatar.com/avatar/598fd02741ac58b88854a99d16704309?s=80&d=identicon',
    web_url: 'http://127.0.0.1:3001/monserrate.gleichner',
    path: '/monserrate.gleichner',
    webPath: '/monserrate.gleichner',
  },
  {
    id: 12,
    name: 'Susy Johnson',
    username: 'tana_harvey',
    state: 'active',
    avatar_url: 'https://www.gravatar.com/avatar/e021a7b0f3e4ae53b5068d487e68c031?s=80&d=identicon',
    web_url: 'http://127.0.0.1:3001/tana_harvey',
    path: '/tana_harvey',
    webPath: '/tana_harvey',
  },
  {
    id: 20,
    name: 'Conchita Eichmann',
    username: 'juliana_gulgowski',
    state: 'active',
    avatar_url: 'https://www.gravatar.com/avatar/c43c506cb6fd7b37017d3b54b94aa937?s=80&d=identicon',
    web_url: 'http://127.0.0.1:3001/juliana_gulgowski',
    path: '/juliana_gulgowski',
    webPath: '/juliana_gulgowski',
  },
  {
    id: 6,
    name: 'Bryce Turcotte',
    username: 'melynda',
    state: 'active',
    avatar_url: 'https://www.gravatar.com/avatar/cc2518f2c6f19f8fac49e1a5ee092a9b?s=80&d=identicon',
    web_url: 'http://127.0.0.1:3001/melynda',
    path: '/melynda',
    webPath: '/melynda',
  },
  {
    id: 1,
    name: 'Administrator',
    username: 'root',
    state: 'active',
    avatar_url: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
    web_url: 'http://127.0.0.1:3001/root',
    path: '/root',
    webPath: '/root',
  },
];

export const mockMilestone = {
  id: 1,
  state: 'active',
  title: 'Milestone title',
  description: 'Harum corporis aut consequatur quae dolorem error sequi quia.',
  start_date: '2018-01-01',
  due_date: '2019-12-31',
};

const assignees = [
  {
    id: 'gid://gitlab/User/2',
    username: 'angelina.herman',
    name: 'Bernardina Bosco',
    avatar: 'https://www.gravatar.com/avatar/eb7b664b13a30ad9f9ba4b61d7075470?s=80&d=identicon',
    webUrl: 'http://127.0.0.1:3000/angelina.herman',
  },
];

export const mockIssueFullPath = 'gitlab-org/test-subgroup/gitlab-test';
export const mockIssueDirectNamespace = 'gitlab-test';
export const rawIssue = {
  title: 'Issue 1',
  titleHtml: 'Issue 1',
  id: 'gid://gitlab/Issue/436',
  iid: '27',
  author: { id: '1', username: 'root' },
  closedAt: null,
  dueDate: null,
  timeEstimate: 0,
  confidential: false,
  referencePath: 'gitlab-org/test-subgroup/gitlab-test#27',
  path: '/gitlab-org/test-subgroup/gitlab-test/-/issues/27',
  labels: {
    nodes: [
      {
        id: 1,
        title: 'test',
        color: '#F0AD4E',
        description: 'testing',
      },
    ],
  },
  assignees: {
    nodes: assignees,
  },
  epic: {
    id: 'gid://gitlab/Epic/41',
  },
  totalTimeSpent: 0,
  humanTimeEstimate: null,
  humanTotalTimeSpent: null,
  emailsDisabled: false,
  hidden: false,
  webPath: `/${mockIssueFullPath}/-/issues/27`,
  webUrl: `http://127.0.0.1:3000/${mockIssueFullPath}/-/issues/27`,
  relativePosition: null,
  severity: null,
  milestone: null,
  weight: null,
  blocked: false,
  blockedByCount: 0,
  blockingCount: 0,
  iteration: null,
  healthStatus: null,
  status: null,
  type: 'ISSUE',
  workItemType: {
    id: 'gid://gitlab/WorkItems::Type/1',
    name: 'Issue',
    iconName: 'work-item-issue',
    __typename: 'WorkItemType',
  },
  linkedWorkItems: {
    __typename: 'LinkedWorkItemTypeConnection',
    nodes: [
      {
        linkId: 'gid://gitlab/WorkItems::RelatedWorkItemLink/103',
        linkType: 'blocks',
        workItemState: 'OPEN',
        __typename: 'LinkedWorkItemType',
      },
    ],
  },
  __typename: 'Issue',
};

export const mockIssue = {
  id: 'gid://gitlab/Issue/436',
  iid: '27',
  author: { id: '1', username: 'root' },
  title: 'Issue 1',
  titleHtml: 'Issue 1',
  closedAt: null,
  dueDate: null,
  timeEstimate: 0,
  confidential: false,
  referencePath: `${mockIssueFullPath}#27`,
  path: `/${mockIssueFullPath}/-/issues/27`,
  assignees: { nodes: assignees },
  labels: {
    nodes: [
      {
        id: 1,
        title: 'test',
        color: '#F0AD4E',
        description: 'testing',
      },
    ],
  },
  epic: {
    id: 'gid://gitlab/Epic/41',
  },
  totalTimeSpent: 0,
  humanTimeEstimate: null,
  humanTotalTimeSpent: null,
  emailsDisabled: false,
  hidden: false,
  webPath: `/${mockIssueFullPath}/-/issues/27`,
  webUrl: `http://127.0.0.1:3000/${mockIssueFullPath}/-/issues/27`,
  relativePosition: null,
  severity: null,
  milestone: null,
  weight: null,
  blocked: false,
  blockedByCount: 1,
  blockingCount: 0,
  iteration: null,
  healthStatus: null,
  status: null,
  type: 'ISSUE',
  workItemType: {
    id: 'gid://gitlab/WorkItems::Type/1',
    name: 'Issue',
    iconName: 'work-item-issue',
    __typename: 'WorkItemType',
  },
  __typename: 'Issue',
  linkedWorkItems: {
    __typename: 'LinkedWorkItemTypeConnection',
    nodes: [
      {
        linkId: 'gid://gitlab/WorkItems::RelatedWorkItemLink/103',
        linkType: 'blocks',
        workItemState: 'OPEN',
        __typename: 'LinkedWorkItemType',
      },
    ],
  },
};

export const mockIssue2 = {
  ...rawIssue,
  id: 'gid://gitlab/Issue/437',
  iid: 28,
  title: 'Issue 2',
  titleHtml: 'Issue 2',
  closedAt: null,
  dueDate: null,
  timeEstimate: 0,
  confidential: false,
  referencePath: 'gitlab-org/test-subgroup/gitlab-test#28',
  path: '/gitlab-org/test-subgroup/gitlab-test/-/issues/28',
  epic: {
    id: 'gid://gitlab/Epic/40',
  },
  linkedWorkItems: {
    __typename: 'LinkedWorkItemTypeConnection',
    nodes: [],
  },
};

const mockIssue3 = {
  ...rawIssue,
  id: 'gid://gitlab/Issue/438',
  iid: 29,
  title: 'Issue 3',
  titleHtml: 'Issue 3',
  referencePath: '#29',
  dueDate: null,
  timeEstimate: 0,
  confidential: false,
  path: '/gitlab-org/gitlab-test/-/issues/28',
  epic: null,
  linkedWorkItems: {
    __typename: 'LinkedWorkItemTypeConnection',
    nodes: [],
  },
};

const mockIssue4 = {
  ...rawIssue,
  id: 'gid://gitlab/Issue/439',
  iid: 30,
  title: 'Issue 4',
  titleHtml: 'Issue 4',
  referencePath: '#30',
  dueDate: null,
  timeEstimate: 0,
  confidential: false,
  path: '/gitlab-org/gitlab-test/-/issues/28',
  epic: null,
  linkedWorkItems: {
    __typename: 'LinkedWorkItemTypeConnection',
    nodes: [],
  },
};

const mockIssue5 = {
  ...rawIssue,
  id: 'gid://gitlab/Issue/440',
  iid: 40,
  title: 'Issue 5',
  titleHtml: 'Issue 5',
  referencePath: '#40',
  dueDate: null,
  timeEstimate: 0,
  confidential: false,
  path: '/gitlab-org/gitlab-test/-/issues/40',
  epic: null,
  linkedWorkItems: {
    __typename: 'LinkedWorkItemTypeConnection',
    nodes: [],
  },
};

const mockIssue6 = {
  ...rawIssue,
  id: 'gid://gitlab/Issue/441',
  iid: 41,
  title: 'Issue  6',
  titleHtml: 'Issue  6',
  referencePath: '#41',
  dueDate: null,
  timeEstimate: 0,
  confidential: false,
  path: '/gitlab-org/gitlab-test/-/issues/41',
  epic: null,
  linkedWorkItems: {
    __typename: 'LinkedWorkItemTypeConnection',
    nodes: [],
  },
};

const mockIssue7 = {
  ...rawIssue,
  id: 'gid://gitlab/Issue/442',
  iid: 42,
  title: 'Issue  6',
  titleHtml: 'Issue  6',
  referencePath: '#42',
  dueDate: null,
  timeEstimate: 0,
  confidential: false,
  path: '/gitlab-org/gitlab-test/-/issues/42',
  epic: null,
  linkedWorkItems: {
    __typename: 'LinkedWorkItemTypeConnection',
    nodes: [],
  },
};

export const mockIssues = [mockIssue, mockIssue2];
export const mockIssuesMore = [
  mockIssue,
  mockIssue2,
  mockIssue3,
  mockIssue4,
  mockIssue5,
  mockIssue6,
  mockIssue7,
];

export const mockList = {
  id: 'gid://gitlab/List/1',
  title: 'Open',
  position: -Infinity,
  listType: 'backlog',
  collapsed: false,
  label: null,
  assignee: null,
  milestone: null,
  iteration: null,
  loading: false,
  issuesCount: 1,
  maxIssueCount: 0,
  maxIssueWeight: 0,
  limitMetric: 'issue_count',
  status: null,
  metadata: {
    epicsCount: 1,
  },
  __typename: 'BoardList',
};

export const labelsQueryResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/33',
      labels: {
        nodes: [
          {
            id: 'gid://gitlab/GroupLabel/121',
            title: 'To Do',
            color: '#F0AD4E',
            textColor: '#FFFFFF',
            description: null,
            descriptionHtml: null,
          },
        ],
      },
      __typename: 'Project',
    },
  },
};

export const mockLabelList = {
  id: 'gid://gitlab/List/2',
  title: 'To Do',
  position: 0,
  listType: 'label',
  collapsed: false,
  label: {
    id: 'gid://gitlab/GroupLabel/121',
    title: 'To Do',
    color: '#F0AD4E',
    textColor: '#FFFFFF',
    description: null,
    descriptionHtml: null,
  },
  assignee: null,
  milestone: null,
  iteration: null,
  loading: false,
  issuesCount: 0,
  maxIssueCount: 0,
  maxIssueWeight: 0,
  status: null,
  limitMetric: 'issue_count',
  __typename: 'BoardList',
};

export const mockStatusList = {
  id: 'gid://gitlab/List/5',
  title: 'In Progress',
  position: 0,
  listType: 'status',
  collapsed: false,
  label: null,
  assignee: null,
  milestone: null,
  iteration: null,
  loading: false,
  issuesCount: 0,
  maxIssueCount: 0,
  maxIssueWeight: 0,
  status: {
    id: 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/2',
    name: 'In progress',
    iconName: 'status-running',
    color: '#1f75cb',
    position: 0,
    __typename: 'WorkItemStatus',
  },
  limitMetric: 'issue_count',
  __typename: 'BoardList',
};

export const mockMilestoneList = {
  id: 'gid://gitlab/List/3',
  title: 'To Do',
  position: 0,
  listType: 'milestone',
  collapsed: false,
  label: null,
  assignee: null,
  milestone: {
    webUrl: 'https://gitlab.com/h5bp/html5-boilerplate/-/milestones/1',
    title: 'Backlog',
  },
  loading: false,
  status: null,
  issuesCount: 0,
};

export const mockLists = [mockList, mockLabelList];

export const mockListsById = keyBy(mockLists, 'id');

const mockGroupProject1 = {
  id: 0,
  name: 'Example Project',
  nameWithNamespace: 'Awesome Group / Example Project',
  fullPath: 'awesome-group/example-project',
  archived: false,
};

const mockGroupProject2 = {
  id: 1,
  name: 'Foobar Project',
  nameWithNamespace: 'Awesome Group / Foobar Project',
  fullPath: 'awesome-group/foobar-project',
  archived: false,
};

export const mockGroupProjects = [mockGroupProject1, mockGroupProject2];

const mockEmojiToken = {
  type: TOKEN_TYPE_MY_REACTION,
  icon: 'thumb-up',
  title: TOKEN_TITLE_MY_REACTION,
  unique: true,
  token: EmojiToken,
  fetchEmojis: typeof expect !== 'undefined' ? expect.any(Function) : () => {},
};

const mockConfidentialToken = {
  type: TOKEN_TYPE_CONFIDENTIAL,
  icon: 'eye-slash',
  title: TOKEN_TITLE_CONFIDENTIAL,
  unique: true,
  token: GlFilteredSearchToken,
  operators: OPERATORS_IS,
  options: [
    { icon: 'eye-slash', value: 'yes', title: 'Yes' },
    { icon: 'eye', value: 'no', title: 'No' },
  ],
};

export const mockTokens = (fetchLabels, isSignedIn) => [
  {
    icon: 'user',
    title: TOKEN_TITLE_ASSIGNEE,
    type: TOKEN_TYPE_ASSIGNEE,
    operators: OPERATORS_IS_NOT,
    token: UserToken,
    dataType: 'user',
    unique: true,
    fullPath: 'gitlab-org',
    isProject: false,
    preloadedUsers: [],
    defaultUsers: isSignedIn ? OPTIONS_NONE_ANY_ME : OPTIONS_NONE_ANY,
  },
  {
    icon: 'pencil',
    title: TOKEN_TITLE_AUTHOR,
    type: TOKEN_TYPE_AUTHOR,
    operators: OPERATORS_IS_NOT,
    symbol: '@',
    token: UserToken,
    dataType: 'user',
    unique: true,
    fullPath: 'gitlab-org',
    isProject: false,
    preloadedUsers: [],
  },
  {
    icon: 'labels',
    title: TOKEN_TITLE_LABEL,
    type: TOKEN_TYPE_LABEL,
    operators: OPERATORS_IS_NOT,
    token: LabelToken,
    unique: false,
    symbol: '~',
    fetchLabels,
    recentSuggestionsStorageKey: 'gitlab-org-board-recent-tokens-label',
  },
  ...(isSignedIn ? [mockEmojiToken, mockConfidentialToken] : []),
  {
    icon: 'milestone',
    title: TOKEN_TITLE_MILESTONE,
    symbol: '%',
    type: TOKEN_TYPE_MILESTONE,
    shouldSkipSort: true,
    token: MilestoneToken,
    unique: true,
    fullPath: 'gitlab-org',
    isProject: false,
  },
  {
    type: TOKEN_TYPE_TYPE,
    title: TOKEN_TITLE_TYPE,
    icon: 'work-item-issue',
    unique: true,
    token: WorkItemTypeToken,
    fullPath: 'gitlab-org',
    isFilterableBoardView: true,
  },
  {
    type: TOKEN_TYPE_RELEASE,
    title: TOKEN_TITLE_RELEASE,
    icon: 'rocket',
    token: ReleaseToken,
    fetchReleases: typeof expect !== 'undefined' ? expect.any(Function) : () => {},
  },
];

export const mockLabel1 = {
  id: 'gid://gitlab/GroupLabel/121',
  title: 'To Do',
  color: '#F0AD4E',
  textColor: '#FFFFFF',
  description: null,
  __typename: 'Label',
};

const mockLabel2 = {
  id: 'gid://gitlab/GroupLabel/122',
  title: 'Doing',
  color: '#F0AD4E',
  textColor: '#FFFFFF',
  description: null,
  __typename: 'Label',
};

export const mockProjectLabelsResponse = {
  data: {
    namespace: {
      id: 'gid://gitlab/Project/1',
      labels: {
        nodes: [mockLabel1, mockLabel2],
      },
      __typename: 'Project',
    },
  },
};

export const mockGroupLabelsResponse = {
  data: {
    namespace: {
      id: 'gid://gitlab/Group/1',
      labels: {
        nodes: [mockLabel1, mockLabel2],
      },
      __typename: 'Group',
    },
  },
};

export const boardListsQueryResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      board: {
        id: 'gid://gitlab/Board/1',
        hideBacklogList: false,
        lists: {
          nodes: mockLists,
        },
      },
      __typename: 'Project',
    },
  },
};

export const issueBoardListsQueryResponse = {
  data: {
    group: {
      id: 'gid://gitlab/Group/1',
      board: {
        id: 'gid://gitlab/Board/1',
        hideBacklogList: false,
        lists: {
          nodes: [mockLabelList],
        },
      },
      __typename: 'Group',
    },
  },
};

export const boardListQueryResponse = ({
  listId = 'gid://gitlab/List/5',
  issuesCount = 20,
} = {}) => ({
  data: {
    boardList: {
      __typename: 'BoardList',
      id: listId,
      totalIssueWeight: '5',
      issuesCount,
    },
  },
});

export const epicBoardListQueryResponse = (totalWeight = 5) => ({
  data: {
    epicBoardList: {
      __typename: 'EpicList',
      id: 'gid://gitlab/Boards::EpicList/3',
      metadata: {
        epicsCount: 1,
        totalWeight,
      },
    },
  },
});

export const createBoardListResponse = {
  data: {
    boardListCreate: {
      list: mockLabelList,
      errors: [],
    },
  },
};

export const updateBoardListResponse = {
  data: {
    updateBoardList: {
      list: mockList,
      errors: [],
    },
  },
};

export const destroyBoardListMutationResponse = {
  data: {
    destroyBoardList: {
      errors: [],
      __typename: 'DestroyBoardListPayload',
    },
  },
};

export const mockProjects = [
  {
    id: 'gid://gitlab/Project/1',
    name: 'Gitlab Shell',
    nameWithNamespace: 'Gitlab Org / Gitlab Shell',
    fullPath: 'gitlab-org/gitlab-shell',
    archived: false,
    __typename: 'Project',
  },
  {
    id: 'gid://gitlab/Project/2',
    name: 'Gitlab Test',
    nameWithNamespace: 'Gitlab Org / Gitlab Test',
    fullPath: 'gitlab-org/gitlab-test',
    archived: true,
    __typename: 'Project',
  },
];

export const mockGroupProjectsResponse = (projects = mockProjects) => ({
  data: {
    group: {
      id: 'gid://gitlab/Group/1',
      projects: {
        nodes: projects,
        pageInfo: {
          hasNextPage: true,
          hasPreviousPage: false,
          startCursor: 'abc',
          endCursor: 'bcd',
          __typename: 'PageInfo',
        },
        __typename: 'ProjectConnection',
      },
      __typename: 'Group',
    },
  },
});

export const mockGroupIssuesResponse = (
  listId = 'gid://gitlab/List/1',
  rawIssues = [rawIssue],
) => ({
  data: {
    group: {
      id: 'gid://gitlab/Group/1',
      board: {
        __typename: 'Board',
        id: 'gid://gitlab/Board/1',
        lists: {
          nodes: [
            {
              id: listId,
              listType: 'backlog',
              issues: {
                nodes: rawIssues,
                pageInfo: {
                  endCursor: null,
                  hasNextPage: true,
                },
              },
              __typename: 'BoardList',
            },
          ],
        },
      },
      __typename: 'Group',
    },
  },
});

export const DEFAULT_COLOR = '#1068bf';

export const mockMilestoneQueryResponse = {
  data: {
    milestone: {
      id: 'gid://gitlab/Milestone/1',
      title: 'v1.0',
      expired: false,
      upcoming: false,
      startDate: '2023-01-01',
      dueDate: '2023-12-31',
      groupMilestone: true,
      group: {
        id: 'gid://gitlab/Group/1',
        fullPath: 'test-group',
        __typename: 'Group',
      },
      projectMilestone: false,
      project: null,
      state: 'active',
      stats: {
        closedIssuesCount: 5,
        totalIssuesCount: 10,
        __typename: 'MilestoneStats',
      },
      __typename: 'Milestone',
    },
  },
};

export const mockMilestoneQueryList = {
  ...mockLabelList,
  listType: 'milestone',
  title: 'v1.0',
  milestone: {
    id: 'gid://gitlab/Milestone/1',
    title: 'v1.0',
  },
};
