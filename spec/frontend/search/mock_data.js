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
