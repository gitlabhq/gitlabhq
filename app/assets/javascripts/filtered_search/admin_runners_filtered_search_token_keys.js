import FilteredSearchTokenKeys from './filtered_search_token_keys';

const tokenKeys = [
  {
    key: 'status',
    type: 'string',
    param: 'status',
    symbol: '',
    icon: 'messages',
    tag: 'status',
  },
  {
    key: 'type',
    type: 'string',
    param: 'type',
    symbol: '',
    icon: 'cube',
    tag: 'type',
  },
  {
    key: 'tag',
    type: 'array',
    param: 'name[]',
    symbol: '~',
    icon: 'tag',
    tag: '~tag',
  },
];

const AdminRunnersFilteredSearchTokenKeys = new FilteredSearchTokenKeys(tokenKeys);

export default AdminRunnersFilteredSearchTokenKeys;
