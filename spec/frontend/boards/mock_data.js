/* global List */

import { keyBy } from 'lodash';
import Vue from 'vue';
import '~/boards/models/list';
import { ListType } from '~/boards/constants';
import boardsStore from '~/boards/stores/boards_store';
import { __ } from '~/locale';
import AuthorToken from '~/vue_shared/components/filtered_search_bar/tokens/author_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';

export const boardObj = {
  id: 1,
  name: 'test',
  milestone_id: null,
};

export const listObj = {
  id: 300,
  position: 0,
  title: 'Test',
  list_type: 'label',
  weight: 3,
  label: {
    id: 5000,
    title: 'Test',
    color: '#ff0000',
    description: 'testing;',
    textColor: 'white',
  },
};

export const listObjDuplicate = {
  id: listObj.id,
  position: 1,
  title: 'Test',
  list_type: 'label',
  weight: 3,
  label: {
    id: listObj.label.id,
    title: 'Test',
    color: '#ff0000',
    description: 'testing;',
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
  },
  {
    id: 12,
    name: 'Susy Johnson',
    username: 'tana_harvey',
    state: 'active',
    avatar_url: 'https://www.gravatar.com/avatar/e021a7b0f3e4ae53b5068d487e68c031?s=80&d=identicon',
    web_url: 'http://127.0.0.1:3001/tana_harvey',
    path: '/tana_harvey',
  },
  {
    id: 20,
    name: 'Conchita Eichmann',
    username: 'juliana_gulgowski',
    state: 'active',
    avatar_url: 'https://www.gravatar.com/avatar/c43c506cb6fd7b37017d3b54b94aa937?s=80&d=identicon',
    web_url: 'http://127.0.0.1:3001/juliana_gulgowski',
    path: '/juliana_gulgowski',
  },
  {
    id: 6,
    name: 'Bryce Turcotte',
    username: 'melynda',
    state: 'active',
    avatar_url: 'https://www.gravatar.com/avatar/cc2518f2c6f19f8fac49e1a5ee092a9b?s=80&d=identicon',
    web_url: 'http://127.0.0.1:3001/melynda',
    path: '/melynda',
  },
  {
    id: 1,
    name: 'Administrator',
    username: 'root',
    state: 'active',
    avatar_url: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
    web_url: 'http://127.0.0.1:3001/root',
    path: '/root',
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

export const assignees = [
  {
    id: 'gid://gitlab/User/2',
    username: 'angelina.herman',
    name: 'Bernardina Bosco',
    avatar: 'https://www.gravatar.com/avatar/eb7b664b13a30ad9f9ba4b61d7075470?s=80&d=identicon',
    webUrl: 'http://127.0.0.1:3000/angelina.herman',
  },
];

export const labels = [
  {
    id: 'gid://gitlab/GroupLabel/5',
    title: 'Cosync',
    color: '#34ebec',
    description: null,
  },
  {
    id: 'gid://gitlab/GroupLabel/6',
    title: 'Brock',
    color: '#e082b6',
    description: null,
  },
];

export const rawIssue = {
  title: 'Issue 1',
  id: 'gid://gitlab/Issue/436',
  iid: '27',
  dueDate: null,
  timeEstimate: 0,
  weight: null,
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
};

export const mockIssueFullPath = 'gitlab-org/test-subgroup/gitlab-test';

export const mockIssue = {
  id: 'gid://gitlab/Issue/436',
  iid: '27',
  title: 'Issue 1',
  dueDate: null,
  timeEstimate: 0,
  weight: null,
  confidential: false,
  referencePath: `${mockIssueFullPath}#27`,
  path: `/${mockIssueFullPath}/-/issues/27`,
  assignees,
  labels: [
    {
      id: 1,
      title: 'test',
      color: '#F0AD4E',
      description: 'testing',
    },
  ],
  epic: {
    id: 'gid://gitlab/Epic/41',
  },
};

export const mockActiveIssue = {
  ...mockIssue,
  id: 436,
  iid: '27',
  subscribed: false,
  emailsDisabled: false,
};

export const mockIssue2 = {
  id: 'gid://gitlab/Issue/437',
  iid: 28,
  title: 'Issue 2',
  dueDate: null,
  timeEstimate: 0,
  weight: null,
  confidential: false,
  referencePath: 'gitlab-org/test-subgroup/gitlab-test#28',
  path: '/gitlab-org/test-subgroup/gitlab-test/-/issues/28',
  assignees,
  labels,
  epic: {
    id: 'gid://gitlab/Epic/40',
  },
};

export const mockIssue3 = {
  id: 'gid://gitlab/Issue/438',
  iid: 29,
  title: 'Issue 3',
  referencePath: '#29',
  dueDate: null,
  timeEstimate: 0,
  weight: null,
  confidential: false,
  path: '/gitlab-org/gitlab-test/-/issues/28',
  assignees,
  labels,
  epic: null,
};

export const mockIssue4 = {
  id: 'gid://gitlab/Issue/439',
  iid: 30,
  title: 'Issue 4',
  referencePath: '#30',
  dueDate: null,
  timeEstimate: 0,
  weight: null,
  confidential: false,
  path: '/gitlab-org/gitlab-test/-/issues/28',
  assignees,
  labels,
  epic: null,
};

export const mockIssues = [mockIssue, mockIssue2];

export const BoardsMockData = {
  GET: {
    '/test/-/boards/1/lists/300/issues?id=300&page=1': {
      issues: [
        {
          title: 'Testing',
          id: 1,
          iid: 1,
          confidential: false,
          labels: [],
          assignees: [],
        },
      ],
    },
    '/test/issue-boards/-/milestones.json': [
      {
        id: 1,
        title: 'test',
      },
    ],
  },
  POST: {
    '/test/-/boards/1/lists': listObj,
  },
  PUT: {
    '/test/issue-boards/-/board/1/lists{/id}': {},
  },
  DELETE: {
    '/test/issue-boards/-/board/1/lists{/id}': {},
  },
};

export const boardsMockInterceptor = (config) => {
  const body = BoardsMockData[config.method.toUpperCase()][config.url];
  return [200, body];
};

export const setMockEndpoints = (opts = {}) => {
  const boardsEndpoint = opts.boardsEndpoint || '/test/issue-boards/-/boards.json';
  const listsEndpoint = opts.listsEndpoint || '/test/-/boards/1/lists';
  const bulkUpdatePath = opts.bulkUpdatePath || '';
  const boardId = opts.boardId || '1';

  boardsStore.setEndpoints({
    boardsEndpoint,
    listsEndpoint,
    bulkUpdatePath,
    boardId,
  });
};

export const mockList = {
  id: 'gid://gitlab/List/1',
  title: 'Backlog',
  position: -Infinity,
  listType: 'backlog',
  collapsed: false,
  label: null,
  assignee: null,
  milestone: null,
  loading: false,
  issuesCount: 1,
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
  },
  assignee: null,
  milestone: null,
  loading: false,
  issuesCount: 0,
};

export const mockLists = [mockList, mockLabelList];

export const mockListsById = keyBy(mockLists, 'id');

export const mockListsWithModel = mockLists.map((listMock) =>
  Vue.observable(new List({ ...listMock, doNotFetchIssues: true })),
);

export const mockIssuesByListId = {
  'gid://gitlab/List/1': [mockIssue.id, mockIssue3.id, mockIssue4.id],
  'gid://gitlab/List/2': mockIssues.map(({ id }) => id),
};

export const participants = [
  {
    id: '1',
    username: 'test',
    name: 'test',
    avatar: '',
    avatarUrl: '',
  },
  {
    id: '2',
    username: 'hello',
    name: 'hello',
    avatar: '',
    avatarUrl: '',
  },
];

export const issues = {
  [mockIssue.id]: mockIssue,
  [mockIssue2.id]: mockIssue2,
  [mockIssue3.id]: mockIssue3,
  [mockIssue4.id]: mockIssue4,
};

// The response from group project REST API
export const mockRawGroupProjects = [
  {
    id: 0,
    name: 'Example Project',
    name_with_namespace: 'Awesome Group / Example Project',
    path_with_namespace: 'awesome-group/example-project',
  },
  {
    id: 1,
    name: 'Foobar Project',
    name_with_namespace: 'Awesome Group / Foobar Project',
    path_with_namespace: 'awesome-group/foobar-project',
  },
];

// The response from GraphQL endpoint
export const mockGroupProject1 = {
  id: 0,
  name: 'Example Project',
  nameWithNamespace: 'Awesome Group / Example Project',
  fullPath: 'awesome-group/example-project',
  archived: false,
};

export const mockGroupProject2 = {
  id: 1,
  name: 'Foobar Project',
  nameWithNamespace: 'Awesome Group / Foobar Project',
  fullPath: 'awesome-group/foobar-project',
  archived: false,
};

export const mockArchivedGroupProject = {
  id: 2,
  name: 'Archived Project',
  nameWithNamespace: 'Awesome Group / Archived Project',
  fullPath: 'awesome-group/archived-project',
  archived: true,
};

export const mockGroupProjects = [mockGroupProject1, mockGroupProject2];

export const mockActiveGroupProjects = [
  { ...mockGroupProject1, archived: false },
  { ...mockGroupProject2, archived: false },
];

export const mockIssueGroupPath = 'gitlab-org';
export const mockIssueProjectPath = `${mockIssueGroupPath}/gitlab-test`;

export const mockBlockingIssue1 = {
  id: 'gid://gitlab/Issue/525',
  iid: '6',
  title: 'blocking issue title 1',
  reference: 'gitlab-org/my-project-1#6',
  webUrl: 'http://gdk.test:3000/gitlab-org/my-project-1/-/issues/6',
  __typename: 'Issue',
};

export const mockBlockingIssue2 = {
  id: 'gid://gitlab/Issue/524',
  iid: '5',
  title:
    'blocking issue title 2 + blocking issue title 2 + blocking issue title 2 + blocking issue title 2',
  reference: 'gitlab-org/my-project-1#5',
  webUrl: 'http://gdk.test:3000/gitlab-org/my-project-1/-/issues/5',
  __typename: 'Issue',
};

export const mockBlockingIssue3 = {
  id: 'gid://gitlab/Issue/523',
  iid: '4',
  title: 'blocking issue title 3',
  reference: 'gitlab-org/my-project-1#4',
  webUrl: 'http://gdk.test:3000/gitlab-org/my-project-1/-/issues/4',
  __typename: 'Issue',
};

export const mockBlockingIssue4 = {
  id: 'gid://gitlab/Issue/522',
  iid: '3',
  title: 'blocking issue title 4',
  reference: 'gitlab-org/my-project-1#3',
  webUrl: 'http://gdk.test:3000/gitlab-org/my-project-1/-/issues/3',
  __typename: 'Issue',
};

export const mockBlockingIssuablesResponse1 = {
  data: {
    issuable: {
      __typename: 'Issue',
      id: 'gid://gitlab/Issue/527',
      blockingIssuables: {
        __typename: 'IssueConnection',
        nodes: [mockBlockingIssue1],
      },
    },
  },
};

export const mockBlockingIssuablesResponse2 = {
  data: {
    issuable: {
      __typename: 'Issue',
      id: 'gid://gitlab/Issue/527',
      blockingIssuables: {
        __typename: 'IssueConnection',
        nodes: [mockBlockingIssue2],
      },
    },
  },
};

export const mockBlockingIssuablesResponse3 = {
  data: {
    issuable: {
      __typename: 'Issue',
      id: 'gid://gitlab/Issue/527',
      blockingIssuables: {
        __typename: 'IssueConnection',
        nodes: [mockBlockingIssue1, mockBlockingIssue2, mockBlockingIssue3, mockBlockingIssue4],
      },
    },
  },
};

export const mockBlockedIssue1 = {
  id: '527',
  blockedByCount: 1,
};

export const mockBlockedIssue2 = {
  id: '527',
  blockedByCount: 4,
  webUrl: 'http://gdk.test:3000/gitlab-org/my-project-1/-/issues/0',
};

export const mockMoveIssueParams = {
  itemId: 1,
  fromListId: 'gid://gitlab/List/1',
  toListId: 'gid://gitlab/List/2',
  moveBeforeId: undefined,
  moveAfterId: undefined,
};

export const mockMoveState = {
  boardLists: {
    'gid://gitlab/List/1': {
      listType: ListType.backlog,
    },
    'gid://gitlab/List/2': {
      listType: ListType.closed,
    },
  },
  boardItems: {
    [mockMoveIssueParams.itemId]: { foo: 'bar' },
  },
  boardItemsByListId: {
    [mockMoveIssueParams.fromListId]: [mockMoveIssueParams.itemId],
    [mockMoveIssueParams.toListId]: [],
  },
};

export const mockMoveData = {
  reordering: false,
  shouldClone: false,
  itemNotInToList: true,
  originalIndex: 0,
  originalIssue: { foo: 'bar' },
  ...mockMoveIssueParams,
};

export const mockTokens = (fetchLabels, fetchAuthors) => [
  {
    icon: 'labels',
    title: __('Label'),
    type: 'label_name',
    operators: [
      { value: '=', description: 'is' },
      { value: '!=', description: 'is not' },
    ],
    token: LabelToken,
    unique: false,
    symbol: '~',
    fetchLabels,
  },
  {
    icon: 'pencil',
    title: __('Author'),
    type: 'author_username',
    operators: [
      { value: '=', description: 'is' },
      { value: '!=', description: 'is not' },
    ],
    symbol: '@',
    token: AuthorToken,
    unique: true,
    fetchAuthors,
  },
  {
    icon: 'user',
    title: __('Assignee'),
    type: 'assignee_username',
    operators: [
      { value: '=', description: 'is' },
      { value: '!=', description: 'is not' },
    ],
    token: AuthorToken,
    unique: true,
    fetchAuthors,
  },
];
