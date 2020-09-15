import { mockLabels } from 'jest/vue_shared/components/sidebar/labels_select_vue/mock_data';
import Api from '~/api';
import AuthorToken from '~/vue_shared/components/filtered_search_bar/tokens/author_token.vue';
import BranchToken from '~/vue_shared/components/filtered_search_bar/tokens/branch_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';
import MilestoneToken from '~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue';

export const mockAuthor1 = {
  id: 1,
  name: 'Administrator',
  username: 'root',
  state: 'active',
  avatar_url: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
  web_url: 'http://0.0.0.0:3000/root',
};

export const mockAuthor2 = {
  id: 2,
  name: 'Claudio Beer',
  username: 'ericka_terry',
  state: 'active',
  avatar_url: 'https://www.gravatar.com/avatar/12a89d115b5a398d5082897ebbcba9c2?s=80&d=identicon',
  web_url: 'http://0.0.0.0:3000/ericka_terry',
};

export const mockAuthor3 = {
  id: 6,
  name: 'Shizue Hartmann',
  username: 'junita.weimann',
  state: 'active',
  avatar_url: 'https://www.gravatar.com/avatar/9da1abb41b1d4c9c9e81030b71ea61a0?s=80&d=identicon',
  web_url: 'http://0.0.0.0:3000/junita.weimann',
};

export const mockAuthors = [mockAuthor1, mockAuthor2, mockAuthor3];

export const mockBranches = [{ name: 'Master' }, { name: 'v1.x' }, { name: 'my-Branch' }];

export const mockRegularMilestone = {
  id: 1,
  name: '4.0',
  title: '4.0',
};

export const mockEscapedMilestone = {
  id: 3,
  name: '5.0 RC1',
  title: '5.0 RC1',
};

export const mockMilestones = [
  {
    id: 2,
    name: '5.0',
    title: '5.0',
  },
  mockRegularMilestone,
  mockEscapedMilestone,
];

export const mockBranchToken = {
  type: 'source_branch',
  icon: 'branch',
  title: 'Source Branch',
  unique: true,
  token: BranchToken,
  operators: [{ value: '=', description: 'is', default: 'true' }],
  fetchBranches: Api.branches.bind(Api),
};

export const mockAuthorToken = {
  type: 'author_username',
  icon: 'user',
  title: 'Author',
  unique: false,
  symbol: '@',
  token: AuthorToken,
  operators: [{ value: '=', description: 'is', default: 'true' }],
  fetchPath: 'gitlab-org/gitlab-test',
  fetchAuthors: Api.projectUsers.bind(Api),
};

export const mockLabelToken = {
  type: 'label_name',
  icon: 'labels',
  title: 'Label',
  unique: false,
  symbol: '~',
  token: LabelToken,
  operators: [{ value: '=', description: 'is', default: 'true' }],
  fetchLabels: () => Promise.resolve(mockLabels),
};

export const mockMilestoneToken = {
  type: 'milestone_title',
  icon: 'clock',
  title: 'Milestone',
  unique: true,
  symbol: '%',
  token: MilestoneToken,
  operators: [{ value: '=', description: 'is', default: 'true' }],
  fetchMilestones: () => Promise.resolve({ data: mockMilestones }),
};

export const mockAvailableTokens = [mockAuthorToken, mockLabelToken, mockMilestoneToken];

export const tokenValueAuthor = {
  type: 'author_username',
  value: {
    data: 'root',
    operator: '=',
  },
};

export const tokenValueLabel = {
  type: 'label_name',
  value: {
    operator: '=',
    data: 'bug',
  },
};

export const tokenValueMilestone = {
  type: 'milestone_title',
  value: {
    operator: '=',
    data: 'v1.0',
  },
};

export const tokenValuePlain = {
  type: 'filtered-search-term',
  value: { data: 'foo' },
};

export const mockHistoryItems = [
  [tokenValueAuthor, tokenValueLabel, tokenValueMilestone, 'duo'],
  [tokenValueAuthor, 'si'],
];

export const mockSortOptions = [
  {
    id: 1,
    title: 'Created date',
    sortDirection: {
      descending: 'created_desc',
      ascending: 'created_asc',
    },
  },
  {
    id: 2,
    title: 'Last updated',
    sortDirection: {
      descending: 'updated_desc',
      ascending: 'updated_asc',
    },
  },
];
