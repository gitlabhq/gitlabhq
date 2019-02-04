import FilteredSearchTokenKeys from './filtered_search_token_keys';

export const tokenKeys = [
  {
    key: 'author',
    type: 'string',
    param: 'username',
    symbol: '@',
    icon: 'pencil',
    tag: '@author',
  },
  {
    key: 'assignee',
    type: 'string',
    param: 'username',
    symbol: '@',
    icon: 'user',
    tag: '@assignee',
  },
  {
    key: 'milestone',
    type: 'string',
    param: 'title',
    symbol: '%',
    icon: 'clock',
    tag: '%milestone',
  },
  {
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
    key: 'label',
    type: 'string',
    param: 'name',
    symbol: '~',
  },
];

export const conditions = [
  {
    url: 'assignee_id=None',
    tokenKey: 'assignee',
    value: 'None',
  },
  {
    url: 'assignee_id=Any',
    tokenKey: 'assignee',
    value: 'Any',
  },
  {
    url: 'milestone_title=None',
    tokenKey: 'milestone',
    value: 'None',
  },
  {
    url: 'milestone_title=Any',
    tokenKey: 'milestone',
    value: 'Any',
  },
  {
    url: 'milestone_title=%23upcoming',
    tokenKey: 'milestone',
    value: 'Upcoming',
  },
  {
    url: 'milestone_title=%23started',
    tokenKey: 'milestone',
    value: 'Started',
  },
  {
    url: 'label_name[]=None',
    tokenKey: 'label',
    value: 'None',
  },
  {
    url: 'label_name[]=Any',
    tokenKey: 'label',
    value: 'Any',
  },
  {
    url: 'my_reaction_emoji=None',
    tokenKey: 'my-reaction',
    value: 'None',
  },
  {
    url: 'my_reaction_emoji=Any',
    tokenKey: 'my-reaction',
    value: 'Any',
  },
];

const IssuableFilteredSearchTokenKeys = new FilteredSearchTokenKeys(
  tokenKeys,
  alternativeTokenKeys,
  conditions,
);

export default IssuableFilteredSearchTokenKeys;
