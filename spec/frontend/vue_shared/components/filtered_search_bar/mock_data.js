import { GlFilteredSearchToken } from '@gitlab/ui';
import { mockLabels } from 'jest/sidebar/components/labels/labels_select_vue/mock_data';
import Api from '~/api';
import {
  FILTERED_SEARCH_TERM,
  OPERATORS_IS,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_CONTACT,
  TOKEN_TITLE_LABEL,
  TOKEN_TITLE_MILESTONE,
  TOKEN_TITLE_MY_REACTION,
  TOKEN_TITLE_ORGANIZATION,
  TOKEN_TITLE_RELEASE,
  TOKEN_TITLE_SOURCE_BRANCH,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_CONTACT,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_ORGANIZATION,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_SOURCE_BRANCH,
} from '~/vue_shared/components/filtered_search_bar/constants';
import { EMOJI_THUMBS_UP } from '~/emoji/constants';
import UserToken from '~/vue_shared/components/filtered_search_bar/tokens/user_token.vue';
import BranchToken from '~/vue_shared/components/filtered_search_bar/tokens/branch_token.vue';
import EmojiToken from '~/vue_shared/components/filtered_search_bar/tokens/emoji_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';
import MilestoneToken from '~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue';
import ReleaseToken from '~/vue_shared/components/filtered_search_bar/tokens/release_token.vue';
import CrmContactToken from '~/vue_shared/components/filtered_search_bar/tokens/crm_contact_token.vue';
import CrmOrganizationToken from '~/vue_shared/components/filtered_search_bar/tokens/crm_organization_token.vue';

export const mockUser1 = {
  id: 1,
  name: 'Administrator',
  username: 'root',
  state: 'active',
  avatar_url: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
  web_url: 'http://0.0.0.0:3000/root',
};

export const mockUser2 = {
  id: 2,
  name: 'Claudio Beer',
  username: 'ericka_terry',
  state: 'active',
  avatar_url: 'https://www.gravatar.com/avatar/12a89d115b5a398d5082897ebbcba9c2?s=80&d=identicon',
  web_url: 'http://0.0.0.0:3000/ericka_terry',
};

export const mockUser3 = {
  id: 6,
  name: 'Shizue Hartmann',
  username: 'junita.weimann',
  state: 'active',
  avatar_url: 'https://www.gravatar.com/avatar/9da1abb41b1d4c9c9e81030b71ea61a0?s=80&d=identicon',
  web_url: 'http://0.0.0.0:3000/junita.weimann',
};

export const mockUsers = [mockUser1, mockUser2, mockUser3];

export const mockBranches = [{ name: 'Main' }, { name: 'v1.x' }, { name: 'my-Branch' }];

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

export const mockDuplicateMilestones = [
  {
    id: 99,
    name: '99.0',
    title: '99.0',
  },
  {
    id: 100,
    name: '99.0',
    title: '99.0',
  },
];

export const mockMilestones = [
  {
    id: 2,
    name: '5.0',
    title: '5.0',
  },
  mockRegularMilestone,
  mockEscapedMilestone,
];

export const projectMilestonesResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      attributes: {
        nodes: mockMilestones,
        __typename: 'MilestoneConnection',
      },
      __typename: 'Project',
    },
  },
};

export const projectUsersResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      attributes: {
        nodes: mockUsers,
        __typename: 'UserConnection',
      },
      __typename: 'Project',
    },
  },
};

export const mockCrmContacts = [
  {
    __typename: 'CustomerRelationsContact',
    id: 'gid://gitlab/CustomerRelations::Contact/1',
    firstName: 'John',
    lastName: 'Smith',
    email: 'john@smith.com',
  },
  {
    __typename: 'CustomerRelationsContact',
    id: 'gid://gitlab/CustomerRelations::Contact/2',
    firstName: 'Andy',
    lastName: 'Green',
    email: 'andy@green.net',
  },
];

export const mockCrmOrganizations = [
  {
    __typename: 'CustomerRelationsOrganization',
    id: 'gid://gitlab/CustomerRelations::Organization/1',
    name: 'First Org Ltd.',
  },
  {
    __typename: 'CustomerRelationsOrganization',
    id: 'gid://gitlab/CustomerRelations::Organization/2',
    name: 'Organizer S.p.a.',
  },
];

export const mockProjectCrmContactsQueryResponse = {
  data: {
    project: {
      __typename: 'Project',
      id: 1,
      group: {
        __typename: 'Group',
        id: 1,
        contacts: {
          __typename: 'CustomerRelationsContactConnection',
          nodes: [
            {
              ...mockCrmContacts[0],
            },
            {
              ...mockCrmContacts[1],
            },
          ],
        },
      },
    },
  },
};

export const mockProjectCrmOrganizationsQueryResponse = {
  data: {
    project: {
      __typename: 'Project',
      id: 1,
      group: {
        __typename: 'Group',
        id: 1,
        organizations: {
          __typename: 'CustomerRelationsOrganizationConnection',
          nodes: [
            {
              ...mockCrmOrganizations[0],
            },
            {
              ...mockCrmOrganizations[1],
            },
          ],
        },
      },
    },
  },
};

export const mockGroupCrmContactsQueryResponse = {
  data: {
    group: {
      __typename: 'Group',
      id: 1,
      contacts: {
        __typename: 'CustomerRelationsContactConnection',
        nodes: [
          {
            __typename: 'CustomerRelationsContact',
            ...mockCrmContacts[0],
          },
          {
            __typename: 'CustomerRelationsContact',
            ...mockCrmContacts[1],
          },
        ],
      },
    },
  },
};

export const mockGroupCrmOrganizationsQueryResponse = {
  data: {
    group: {
      __typename: 'Group',
      id: 1,
      organizations: {
        __typename: 'CustomerRelationsOrganizationConnection',
        nodes: [
          {
            __typename: 'CustomerRelationsOrganization',
            ...mockCrmOrganizations[0],
          },
          {
            __typename: 'CustomerRelationsOrganization',
            ...mockCrmOrganizations[1],
          },
        ],
      },
    },
  },
};

export const mockEmoji1 = {
  name: EMOJI_THUMBS_UP,
};

export const mockEmoji2 = {
  name: 'star',
};

export const mockEmojis = [mockEmoji1, mockEmoji2];

export const mockBranchToken = {
  type: TOKEN_TYPE_SOURCE_BRANCH,
  icon: 'branch',
  title: TOKEN_TITLE_SOURCE_BRANCH,
  unique: true,
  token: BranchToken,
  operators: OPERATORS_IS,
  fetchBranches: Api.branches.bind(Api),
};

export const mockAuthorToken = {
  type: TOKEN_TYPE_AUTHOR,
  icon: 'user',
  title: TOKEN_TITLE_AUTHOR,
  unique: false,
  symbol: '@',
  token: UserToken,
  operators: OPERATORS_IS,
  fullPath: 'gitlab-org/gitlab-test',
  isProject: true,
};

export const mockLabelToken = {
  type: TOKEN_TYPE_LABEL,
  icon: 'labels',
  title: TOKEN_TITLE_LABEL,
  unique: false,
  symbol: '~',
  token: LabelToken,
  operators: OPERATORS_IS,
  fetchLabels: () => Promise.resolve(mockLabels),
};

export const mockMilestoneToken = {
  type: TOKEN_TYPE_MILESTONE,
  icon: 'milestone',
  title: TOKEN_TITLE_MILESTONE,
  unique: true,
  symbol: '%',
  token: MilestoneToken,
  operators: OPERATORS_IS,
  fullPath: 'gitlab-org',
  isProject: true,
};

export const mockReleaseToken = {
  type: TOKEN_TYPE_RELEASE,
  icon: 'rocket',
  title: TOKEN_TITLE_RELEASE,
  token: ReleaseToken,
  fetchReleases: () => Promise.resolve(),
};

export const mockReactionEmojiToken = {
  type: TOKEN_TYPE_MY_REACTION,
  icon: 'thumb-up',
  title: TOKEN_TITLE_MY_REACTION,
  unique: true,
  token: EmojiToken,
  operators: OPERATORS_IS,
  fetchEmojis: () => Promise.resolve(mockEmojis),
};

export const mockCrmContactToken = {
  type: TOKEN_TYPE_CONTACT,
  title: TOKEN_TITLE_CONTACT,
  icon: 'user',
  token: CrmContactToken,
  isProject: false,
  fullPath: 'group',
  operators: OPERATORS_IS,
  unique: true,
};

export const mockCrmOrganizationToken = {
  type: TOKEN_TYPE_ORGANIZATION,
  title: TOKEN_TITLE_ORGANIZATION,
  icon: 'user',
  token: CrmOrganizationToken,
  isProject: false,
  fullPath: 'group',
  operators: OPERATORS_IS,
  unique: true,
};

export const mockMembershipToken = {
  type: 'with_inherited_permissions',
  icon: 'group',
  title: 'Membership',
  token: GlFilteredSearchToken,
  unique: true,
  operators: OPERATORS_IS,
  options: [
    { value: 'exclude', title: 'Direct' },
    { value: 'only', title: 'Inherited' },
  ],
};

export const mockMembershipTokenOptionsWithoutTitles = {
  ...mockMembershipToken,
  options: [{ value: 'exclude' }, { value: 'only' }],
};

export const mockAvailableTokens = [mockAuthorToken, mockLabelToken, mockMilestoneToken];

export const tokenValueAuthor = {
  type: TOKEN_TYPE_AUTHOR,
  value: {
    data: 'root',
    operator: '=',
  },
};

export const tokenValueLabel = {
  type: TOKEN_TYPE_LABEL,
  value: {
    operator: '=',
    data: 'bug',
  },
};

export const tokenValueMilestone = {
  type: TOKEN_TYPE_MILESTONE,
  value: {
    operator: '=',
    data: 'v1.0',
  },
};

export const tokenValueMembership = {
  type: 'with_inherited_permissions',
  value: {
    operator: '=',
    data: 'exclude',
  },
};

export const tokenValueConfidential = {
  type: TOKEN_TYPE_CONFIDENTIAL,
  value: {
    operator: '=',
    data: true,
  },
};

export const tokenValuePlain = {
  type: FILTERED_SEARCH_TERM,
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
