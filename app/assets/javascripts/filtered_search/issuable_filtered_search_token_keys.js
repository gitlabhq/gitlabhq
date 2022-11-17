import { flattenDeep } from 'lodash';
import { __ } from '~/locale';
import {
  TOKEN_TITLE_ASSIGNEE,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_LABEL,
  TOKEN_TITLE_MILESTONE,
  TOKEN_TITLE_MY_REACTION,
  TOKEN_TITLE_RELEASE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchTokenKeys from './filtered_search_token_keys';

export const tokenKeys = [
  {
    formattedKey: TOKEN_TITLE_AUTHOR,
    key: 'author',
    type: 'string',
    param: 'username',
    symbol: '@',
    icon: 'pencil',
    tag: '@author',
  },
  {
    formattedKey: TOKEN_TITLE_ASSIGNEE,
    key: 'assignee',
    type: 'string',
    param: 'username',
    symbol: '@',
    icon: 'user',
    tag: '@assignee',
  },
  {
    formattedKey: TOKEN_TITLE_MILESTONE,
    key: 'milestone',
    type: 'string',
    param: 'title',
    symbol: '%',
    icon: 'clock',
    tag: '%milestone',
  },
  {
    formattedKey: TOKEN_TITLE_RELEASE,
    key: 'release',
    type: 'string',
    param: 'tag',
    symbol: '',
    icon: 'rocket',
    tag: __('tag name'),
  },
  {
    formattedKey: TOKEN_TITLE_LABEL,
    key: 'label',
    type: 'array',
    param: 'name[]',
    symbol: '~',
    icon: 'labels',
    tag: '~label',
  },
];

if (gon.current_user_id) {
  // Appending tokenkeys only logged-in
  tokenKeys.push({
    formattedKey: TOKEN_TITLE_MY_REACTION,
    key: 'my-reaction',
    type: 'string',
    param: 'emoji',
    symbol: '',
    icon: 'thumb-up',
    tag: 'emoji',
  });
}

export const alternativeTokenKeys = [
  {
    formattedKey: TOKEN_TITLE_LABEL,
    key: 'label',
    type: 'string',
    param: 'name',
    symbol: '~',
  },
];

export const conditions = flattenDeep(
  [
    {
      url: 'assignee_id=None',
      tokenKey: 'assignee',
      value: __('None'),
    },
    {
      url: 'assignee_id=Any',
      tokenKey: 'assignee',
      value: __('Any'),
    },
    {
      url: 'reviewer_id=None',
      tokenKey: 'reviewer',
      value: __('None'),
    },
    {
      url: 'reviewer_id=Any',
      tokenKey: 'reviewer',
      value: __('Any'),
    },
    {
      url: 'author_username=support-bot',
      tokenKey: 'author',
      value: 'support-bot',
    },
    {
      url: 'milestone_title=None',
      tokenKey: 'milestone',
      value: __('None'),
    },
    {
      url: 'milestone_title=Any',
      tokenKey: 'milestone',
      value: __('Any'),
    },
    {
      url: 'milestone_title=%23upcoming',
      tokenKey: 'milestone',
      value: __('Upcoming'),
    },
    {
      url: 'milestone_title=%23started',
      tokenKey: 'milestone',
      value: __('Started'),
    },
    {
      url: 'release_tag=None',
      tokenKey: 'release',
      value: __('None'),
    },
    {
      url: 'release_tag=Any',
      tokenKey: 'release',
      value: __('Any'),
    },
    {
      url: 'label_name[]=None',
      tokenKey: 'label',
      value: __('None'),
    },
    {
      url: 'label_name[]=Any',
      tokenKey: 'label',
      value: __('Any'),
    },
    {
      url: 'my_reaction_emoji=None',
      tokenKey: 'my-reaction',
      value: __('None'),
    },
    {
      url: 'my_reaction_emoji=Any',
      tokenKey: 'my-reaction',
      value: __('Any'),
    },
  ].map((condition) => {
    const [keyPart, valuePart] = condition.url.split('=');
    const hasBrackets = keyPart.includes('[]');

    const notEqualUrl = `not[${hasBrackets ? keyPart.slice(0, -2) : keyPart}]${
      hasBrackets ? '[]' : ''
    }=${valuePart}`;
    return [
      {
        ...condition,
        operator: '=',
      },
      {
        ...condition,
        operator: '!=',
        url: notEqualUrl,
      },
    ];
  }),
);

const IssuableFilteredSearchTokenKeys = new FilteredSearchTokenKeys(
  tokenKeys,
  alternativeTokenKeys,
  conditions,
);

export default IssuableFilteredSearchTokenKeys;
