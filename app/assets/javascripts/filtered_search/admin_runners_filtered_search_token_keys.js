import { __ } from '~/locale';
import FilteredSearchTokenKeys from './filtered_search_token_keys';

const tokenKeys = [
  {
    formattedKey: __('Status'),
    key: 'status',
    type: 'string',
    param: 'status',
    symbol: '',
    icon: 'messages',
    tag: 'status',
  },
  {
    formattedKey: __('Type'),
    key: 'type',
    type: 'string',
    param: 'type',
    symbol: '',
    icon: 'cube',
    tag: 'type',
  },
  {
    formattedKey: __('Tag'),
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
