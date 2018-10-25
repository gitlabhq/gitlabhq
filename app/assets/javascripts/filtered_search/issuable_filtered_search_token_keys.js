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
    url: 'assignee_id=0',
    tokenKey: 'assignee',
    value: 'none',
  },
  {
    url: 'milestone_title=No+Milestone',
    tokenKey: 'milestone',
    value: 'none',
  },
  {
    url: 'milestone_title=Any+Milestone',
    tokenKey: 'milestone',
    value: 'any',
  },
  {
    url: 'milestone_title=%23upcoming',
    tokenKey: 'milestone',
    value: 'upcoming',
  },
  {
    url: 'milestone_title=%23started',
    tokenKey: 'milestone',
    value: 'started',
  },
  {
    url: 'label_name[]=No+Label',
    tokenKey: 'label',
    value: 'none',
  },
];

const IssuableFilteredSearchTokenKeys = new FilteredSearchTokenKeys(
  tokenKeys,
  alternativeTokenKeys,
  conditions,
);

export default IssuableFilteredSearchTokenKeys;
