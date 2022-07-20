import { GlFilteredSearchToken } from '@gitlab/ui';
import { mockLabels } from 'jest/vue_shared/components/sidebar/labels_select_vue/mock_data';
import Api from '~/api';
import { OPERATOR_IS_ONLY } from '~/vue_shared/components/filtered_search_bar/constants';
import AuthorToken from '~/vue_shared/components/filtered_search_bar/tokens/author_token.vue';
import BranchToken from '~/vue_shared/components/filtered_search_bar/tokens/branch_token.vue';
import EmojiToken from '~/vue_shared/components/filtered_search_bar/tokens/emoji_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';
import MilestoneToken from '~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue';
import ReleaseToken from '~/vue_shared/components/filtered_search_bar/tokens/release_token.vue';
import CrmContactToken from '~/vue_shared/components/filtered_search_bar/tokens/crm_contact_token.vue';
import CrmOrganizationToken from '~/vue_shared/components/filtered_search_bar/tokens/crm_organization_token.vue';

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

export const mockMilestones = [
  {
    id: 2,
    name: '5.0',
    title: '5.0',
  },
  mockRegularMilestone,
  mockEscapedMilestone,
];

export const mockCrmContacts = [
  {
    id: 'gid://gitlab/CustomerRelations::Contact/1',
    firstName: 'John',
    lastName: 'Smith',
    email: 'john@smith.com',
  },
  {
    id: 'gid://gitlab/CustomerRelations::Contact/2',
    firstName: 'Andy',
    lastName: 'Green',
    email: 'andy@green.net',
  },
];

export const mockCrmOrganizations = [
  {
    id: 'gid://gitlab/CustomerRelations::Organization/1',
    name: 'First Org Ltd.',
  },
  {
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
  name: 'thumbsup',
};

export const mockEmoji2 = {
  name: 'star',
};

export const mockEmojis = [mockEmoji1, mockEmoji2];

export const mockBranchToken = {
  type: 'source_branch',
  icon: 'branch',
  title: 'Source Branch',
  unique: true,
  token: BranchToken,
  operators: OPERATOR_IS_ONLY,
  fetchBranches: Api.branches.bind(Api),
};

export const mockAuthorToken = {
  type: 'author_username',
  icon: 'user',
  title: 'Author',
  unique: false,
  symbol: '@',
  token: AuthorToken,
  operators: OPERATOR_IS_ONLY,
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
  operators: OPERATOR_IS_ONLY,
  fetchLabels: () => Promise.resolve(mockLabels),
};

export const mockMilestoneToken = {
  type: 'milestone_title',
  icon: 'clock',
  title: 'Milestone',
  unique: true,
  symbol: '%',
  token: MilestoneToken,
  operators: OPERATOR_IS_ONLY,
  fetchMilestones: () => Promise.resolve({ data: mockMilestones }),
};

export const mockReleaseToken = {
  type: 'release',
  icon: 'rocket',
  title: 'Release',
  token: ReleaseToken,
  fetchReleases: () => Promise.resolve(),
};

export const mockReactionEmojiToken = {
  type: 'my_reaction_emoji',
  icon: 'thumb-up',
  title: 'My-Reaction',
  unique: true,
  token: EmojiToken,
  operators: OPERATOR_IS_ONLY,
  fetchEmojis: () => Promise.resolve(mockEmojis),
};

export const mockCrmContactToken = {
  type: 'crm_contact',
  title: 'Contact',
  icon: 'user',
  token: CrmContactToken,
  isProject: false,
  fullPath: 'group',
  operators: OPERATOR_IS_ONLY,
  unique: true,
};

export const mockCrmOrganizationToken = {
  type: 'crm_contact',
  title: 'Organization',
  icon: 'user',
  token: CrmOrganizationToken,
  isProject: false,
  fullPath: 'group',
  operators: OPERATOR_IS_ONLY,
  unique: true,
};

export const mockMembershipToken = {
  type: 'with_inherited_permissions',
  icon: 'group',
  title: 'Membership',
  token: GlFilteredSearchToken,
  unique: true,
  operators: OPERATOR_IS_ONLY,
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

export const tokenValueMembership = {
  type: 'with_inherited_permissions',
  value: {
    operator: '=',
    data: 'exclude',
  },
};

export const tokenValueConfidential = {
  type: 'confidential',
  value: {
    operator: '=',
    data: true,
  },
};

export const tokenValuePlain = {
  type: 'filtered-search-term',
  value: { data: 'foo' },
};

export const tokenValueEmpty = {
  type: 'filtered-search-term',
  value: { data: '' },
};

export const tokenValueEpic = {
  type: 'epic_iid',
  value: {
    operator: '=',
    data: '"foo"::&42',
  },
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
