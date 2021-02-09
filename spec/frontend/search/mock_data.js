export const MOCK_QUERY = {
  scope: 'issues',
  state: 'all',
  confidential: null,
  group_id: 'test_1',
};

export const MOCK_GROUP = {
  name: 'test group',
  full_name: 'full name test group',
  id: 'test_1',
};

export const MOCK_GROUPS = [
  {
    name: 'test group',
    full_name: 'full name test group',
    id: 'test_1',
  },
  {
    name: 'test group 2',
    full_name: 'full name test group 2',
    id: 'test_2',
  },
];

export const MOCK_PROJECT = {
  name: 'test project',
  namespace: MOCK_GROUP,
  nameWithNamespace: 'test group test project',
  id: 'test_1',
};

export const MOCK_PROJECTS = [
  {
    name: 'test project',
    namespace: MOCK_GROUP,
    name_with_namespace: 'test group test project',
    id: 'test_1',
  },
  {
    name: 'test project 2',
    namespace: MOCK_GROUP,
    name_with_namespace: 'test group test project 2',
    id: 'test_2',
  },
];

export const MOCK_SORT_OPTIONS = [
  {
    title: 'Most relevant',
    sortable: false,
    sortParam: 'relevant',
  },
  {
    title: 'Created date',
    sortable: true,
    sortParam: {
      asc: 'created_asc',
      desc: 'created_desc',
    },
  },
];

export const MOCK_SEARCH_COUNTS_INPUT = {
  scopeTabs: ['issues', 'snippet_titles', 'merge_requests'],
  activeCount: '15',
};

export const MOCK_SEARCH_COUNT = { scope: 'issues', count: '15' };

export const MOCK_SEARCH_COUNTS_SUCCESS = [
  { scope: 'issues', count: '15' },
  { scope: 'snippet_titles', count: '15' },
  { scope: 'merge_requests', count: '15' },
];

export const MOCK_SEARCH_COUNTS = [
  { scope: 'issues', count: '15' },
  { scope: 'snippet_titles', count: '5' },
  { scope: 'merge_requests', count: '1' },
];

export const MOCK_SCOPE_TABS = [
  { scope: 'issues', title: 'Issues', count: '15' },
  { scope: 'snippet_titles', title: 'Titles and Descriptions', count: '5' },
  { scope: 'merge_requests', title: 'Merge requests', count: '1' },
];
