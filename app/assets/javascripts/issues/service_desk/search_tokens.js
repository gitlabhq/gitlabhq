import { GlFilteredSearchToken } from '@gitlab/ui';
import {
  OPERATORS_IS,
  TOKEN_TITLE_ASSIGNEE,
  TOKEN_TITLE_CONFIDENTIAL,
  TOKEN_TITLE_LABEL,
  TOKEN_TITLE_MILESTONE,
  TOKEN_TITLE_MY_REACTION,
  TOKEN_TITLE_RELEASE,
  TOKEN_TITLE_SEARCH_WITHIN,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_SEARCH_WITHIN,
} from '~/vue_shared/components/filtered_search_bar/constants';
import { titles, descriptions, yes, no } from './constants';

const UserToken = () => import('~/vue_shared/components/filtered_search_bar/tokens/user_token.vue');
const EmojiToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/emoji_token.vue');
const LabelToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/label_token.vue');
const MilestoneToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue');
const ReleaseToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/release_token.vue');

export const searchWithinTokenBase = {
  type: TOKEN_TYPE_SEARCH_WITHIN,
  title: TOKEN_TITLE_SEARCH_WITHIN,
  icon: 'search',
  token: GlFilteredSearchToken,
  unique: true,
  operators: OPERATORS_IS,
  options: [
    { icon: 'title', value: 'TITLE', title: titles },
    {
      icon: 'text-description',
      value: 'DESCRIPTION',
      title: descriptions,
    },
  ],
};

export const assigneeTokenBase = {
  type: TOKEN_TYPE_ASSIGNEE,
  title: TOKEN_TITLE_ASSIGNEE,
  icon: 'user',
  token: UserToken,
  dataType: 'user',
};

export const milestoneTokenBase = {
  type: TOKEN_TYPE_MILESTONE,
  title: TOKEN_TITLE_MILESTONE,
  icon: 'milestone',
  token: MilestoneToken,
  shouldSkipSort: true,
};

export const labelTokenBase = {
  type: TOKEN_TYPE_LABEL,
  title: TOKEN_TITLE_LABEL,
  icon: 'labels',
  token: LabelToken,
};

export const releaseTokenBase = {
  type: TOKEN_TYPE_RELEASE,
  title: TOKEN_TITLE_RELEASE,
  icon: 'rocket',
  token: ReleaseToken,
};

export const reactionTokenBase = {
  type: TOKEN_TYPE_MY_REACTION,
  title: TOKEN_TITLE_MY_REACTION,
  icon: 'thumb-up',
  token: EmojiToken,
  unique: true,
};

export const confidentialityTokenBase = {
  type: TOKEN_TYPE_CONFIDENTIAL,
  title: TOKEN_TITLE_CONFIDENTIAL,
  icon: 'eye-slash',
  token: GlFilteredSearchToken,
  unique: true,
  operators: OPERATORS_IS,
  options: [
    { icon: 'eye-slash', value: 'yes', title: yes },
    { icon: 'eye', value: 'no', title: no },
  ],
};
