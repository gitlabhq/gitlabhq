import { flattenDeep } from 'lodash';
import { __ } from '~/locale';
import {
  TOKEN_TITLE_ASSIGNEE,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_LABEL,
  TOKEN_TITLE_MILESTONE,
  TOKEN_TITLE_MY_REACTION,
  TOKEN_TITLE_RELEASE,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_REVIEWER,
} from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchTokenKeys from './filtered_search_token_keys';

export const createTokenKeys = ({ disableReleaseFilter = false } = {}) => {
  const tokenKeys = [
    {
      formattedKey: TOKEN_TITLE_AUTHOR,
      key: TOKEN_TYPE_AUTHOR,
      type: 'string',
      param: 'username',
      symbol: '@',
      icon: 'pencil',
      tag: '@author',
    },
    {
      formattedKey: TOKEN_TITLE_ASSIGNEE,
      key: TOKEN_TYPE_ASSIGNEE,
      type: 'string',
      param: 'username',
      symbol: '@',
      icon: 'user',
      tag: '@assignee',
    },
    {
      formattedKey: TOKEN_TITLE_MILESTONE,
      key: TOKEN_TYPE_MILESTONE,
      type: 'string',
      param: 'title',
      symbol: '%',
      icon: 'milestone',
      tag: '%milestone',
    },
    {
      formattedKey: TOKEN_TITLE_LABEL,
      key: TOKEN_TYPE_LABEL,
      type: 'array',
      param: 'name[]',
      symbol: '~',
      icon: 'labels',
      tag: '~label',
    },
  ];

  if (!disableReleaseFilter) {
    tokenKeys.push({
      formattedKey: TOKEN_TITLE_RELEASE,
      key: TOKEN_TYPE_RELEASE,
      type: 'string',
      param: 'tag',
      symbol: '',
      icon: 'rocket',
      tag: __('tag name'),
    });
  }

  if (gon.current_user_id) {
    // Appending tokenkeys only logged-in
    tokenKeys.push({
      formattedKey: TOKEN_TITLE_MY_REACTION,
      key: TOKEN_TYPE_MY_REACTION,
      type: 'string',
      param: 'emoji',
      symbol: '',
      icon: 'thumb-up',
      tag: 'emoji',
    });
  }

  return tokenKeys;
};

export const tokenKeys = createTokenKeys();

export const alternativeTokenKeys = [
  {
    formattedKey: TOKEN_TITLE_LABEL,
    key: TOKEN_TYPE_LABEL,
    type: 'string',
    param: 'name',
    symbol: '~',
  },
];

export const conditions = flattenDeep(
  [
    {
      url: 'assignee_id=None',
      tokenKey: TOKEN_TYPE_ASSIGNEE,
      value: __('None'),
    },
    {
      url: 'assignee_id=Any',
      tokenKey: TOKEN_TYPE_ASSIGNEE,
      value: __('Any'),
    },
    {
      url: 'reviewer_id=None',
      tokenKey: TOKEN_TYPE_REVIEWER,
      value: __('None'),
    },
    {
      url: 'reviewer_id=Any',
      tokenKey: TOKEN_TYPE_REVIEWER,
      value: __('Any'),
    },
    {
      url: 'author_username=support-bot',
      tokenKey: TOKEN_TYPE_AUTHOR,
      value: 'support-bot',
    },
    {
      url: 'milestone_title=None',
      tokenKey: TOKEN_TYPE_MILESTONE,
      value: __('None'),
    },
    {
      url: 'milestone_title=Any',
      tokenKey: TOKEN_TYPE_MILESTONE,
      value: __('Any'),
    },
    {
      url: 'milestone_title=%23upcoming',
      tokenKey: TOKEN_TYPE_MILESTONE,
      value: __('Upcoming'),
    },
    {
      url: 'milestone_title=%23started',
      tokenKey: TOKEN_TYPE_MILESTONE,
      value: __('Started'),
    },
    {
      url: 'release_tag=None',
      tokenKey: TOKEN_TYPE_RELEASE,
      value: __('None'),
    },
    {
      url: 'release_tag=Any',
      tokenKey: TOKEN_TYPE_RELEASE,
      value: __('Any'),
    },
    {
      url: 'label_name[]=None',
      tokenKey: TOKEN_TYPE_LABEL,
      value: __('None'),
    },
    {
      url: 'label_name[]=Any',
      tokenKey: TOKEN_TYPE_LABEL,
      value: __('Any'),
    },
    {
      url: 'my_reaction_emoji=None',
      tokenKey: TOKEN_TYPE_MY_REACTION,
      value: __('None'),
    },
    {
      url: 'my_reaction_emoji=Any',
      tokenKey: TOKEN_TYPE_MY_REACTION,
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

export const createFilteredSearchTokenKeys = (config = {}) =>
  new FilteredSearchTokenKeys(createTokenKeys(config), alternativeTokenKeys, conditions);

export default createFilteredSearchTokenKeys();
