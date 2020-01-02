import { flatten } from 'underscore';
import FilteredSearchTokenKeys from './filtered_search_token_keys';
import { __ } from '~/locale';

export const tokenKeys = [
  {
    formattedKey: __('Author'),
    key: 'author',
    type: 'string',
    param: 'username',
    symbol: '@',
    icon: 'pencil',
    tag: '@author',
  },
  {
    formattedKey: __('Assignee'),
    key: 'assignee',
    type: 'string',
    param: 'username',
    symbol: '@',
    icon: 'user',
    tag: '@assignee',
  },
  {
    formattedKey: __('Milestone'),
    key: 'milestone',
    type: 'string',
    param: 'title',
    symbol: '%',
    icon: 'clock',
    tag: '%milestone',
  },
  {
    formattedKey: __('Release'),
    key: 'release',
    type: 'string',
    param: 'tag',
    symbol: '',
    icon: 'rocket',
    tag: __('tag name'),
  },
  {
    formattedKey: __('Label'),
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
    formattedKey: __('My-Reaction'),
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
    formattedKey: __('Label'),
    key: 'label',
    type: 'string',
    param: 'name',
    symbol: '~',
  },
];

export const conditions = flatten(
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
  ].map(condition => {
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
