import FilteredSearchTokenKeys from '~/filtered_search/filtered_search_token_keys';

const tokenKeys = [
  {
    key: 'author',
    type: 'string',
    param: 'username',
    symbol: '@',
    icon: 'pencil',
    tag: '@author',
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

const alternativeTokenKeys = [
  {
    key: 'label',
    type: 'string',
    param: 'name',
    symbol: '~',
  },
];

const conditions = [
  {
    url: 'label_name[]=No+Label',
    tokenKey: 'label',
    value: 'none',
  },
];

const EpicsFilteredSearchTokenKeysEE = new FilteredSearchTokenKeys(
  [...tokenKeys],
  alternativeTokenKeys,
  [...conditions],
);

export default EpicsFilteredSearchTokenKeysEE;
