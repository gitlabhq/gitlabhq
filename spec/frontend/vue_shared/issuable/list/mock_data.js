import {
  mockAuthorToken,
  mockLabelToken,
  mockSortOptions,
} from 'jest/vue_shared/components/filtered_search_bar/mock_data';

export const mockAuthor = {
  id: 'gid://gitlab/User/1',
  avatarUrl: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
  name: 'Administrator',
  username: 'root',
  webUrl: 'http://0.0.0.0:3000/root',
};

export const mockRegularLabel = {
  id: 'gid://gitlab/GroupLabel/2048',
  title: 'Documentation Update',
  description: null,
  color: '#F0AD4E',
  textColor: '#FFFFFF',
};

export const mockScopedLabel = {
  id: 'gid://gitlab/ProjectLabel/2049',
  title: 'status::confirmed',
  description: null,
  color: '#D9534F',
  textColor: '#FFFFFF',
};

export const mockLabels = [mockRegularLabel, mockScopedLabel];

export const mockCurrentUserTodo = {
  id: 'gid://gitlab/Todo/489',
  state: 'done',
};

export const mockIssuable = {
  iid: '30',
  title: 'Dismiss Cipher with no integrity',
  titleHtml: 'Dismiss Cipher with no integrity',
  description: 'fortitudinis _fomentis_ dolor mitigari solet.',
  descriptionHtml: 'fortitudinis <i>fomentis</i> dolor mitigari solet.',
  state: 'opened',
  createdAt: '2020-06-29T13:52:56Z',
  updatedAt: '2020-09-10T11:41:13Z',
  webUrl: 'http://0.0.0.0:3000/gitlab-org/gitlab-shell/-/issues/30',
  blocked: false,
  confidential: false,
  author: mockAuthor,
  labels: {
    nodes: mockLabels,
  },
  assignees: [mockAuthor],
  userDiscussionsCount: 2,
  taskCompletionStatus: {
    count: 2,
    completedCount: 1,
  },
};

export const mockIssuables = [
  mockIssuable,
  {
    iid: '28',
    title: 'Dismiss Cipher with no integrity',
    description: null,
    createdAt: '2020-06-29T13:52:56Z',
    updatedAt: '2020-06-29T13:52:56Z',
    webUrl: 'http://0.0.0.0:3000/gitlab-org/gitlab-shell/-/issues/28',
    author: mockAuthor,
    labels: {
      nodes: [],
    },
  },
  {
    iid: '7',
    title: 'Temporibus in veritatis labore explicabo velit molestiae sed.',
    description: 'Quo consequatur rem aliquid laborum quibusdam molestiae saepe.',
    createdAt: '2020-06-25T13:50:14Z',
    updatedAt: '2020-08-25T06:09:27Z',
    webUrl: 'http://0.0.0.0:3000/gitlab-org/gitlab-shell/-/issues/7',
    author: mockAuthor,
    labels: {
      nodes: mockLabels,
    },
  },
  {
    iid: '17',
    title: 'Vel voluptatem quaerat est hic incidunt qui ut aliquid sit exercitationem.',
    description: 'Incidunt accusamus perspiciatis aut excepturi.',
    createdAt: '2020-06-19T13:51:36Z',
    updatedAt: '2020-08-11T13:36:35Z',
    webUrl: 'http://0.0.0.0:3000/gitlab-org/gitlab-shell/-/issues/17',
    author: mockAuthor,
    labels: {
      nodes: [],
    },
  },
  {
    iid: '16',
    title: 'Vero qui quo labore libero omnis quisquam et cumque.',
    description: 'Ipsa ipsum magni nostrum alias aut exercitationem.',
    createdAt: '2020-06-19T13:51:36Z',
    updatedAt: '2020-06-19T13:51:36Z',
    webUrl: 'http://0.0.0.0:3000/gitlab-org/gitlab-shell/-/issues/16',
    author: mockAuthor,
    labels: {
      nodes: [],
    },
  },
];

export const mockTabs = [
  {
    id: 'state-opened',
    name: 'opened',
    title: 'Open',
    titleTooltip: 'Filter by issuables that are currently opened.',
  },
  {
    id: 'state-archived',
    name: 'closed',
    title: 'Closed',
    titleTooltip: 'Filter by issuables that are currently archived.',
  },
  {
    id: 'state-all',
    name: 'all',
    title: 'All',
    titleTooltip: 'Show all issuables.',
  },
];

export const mockTabCounts = {
  opened: 5,
  closed: 0,
  all: undefined,
};

export const mockIssuableListProps = {
  namespace: 'gitlab-org/gitlab-test',
  recentSearchesStorageKey: 'issues',
  searchInputPlaceholder: 'Search issues',
  searchTokens: [mockAuthorToken, mockLabelToken],
  sortOptions: mockSortOptions,
  issuables: mockIssuables,
  tabs: mockTabs,
  tabCounts: mockTabCounts,
  currentTab: 'opened',
};
