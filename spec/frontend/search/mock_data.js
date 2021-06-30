export const MOCK_QUERY = {
  scope: 'issues',
  state: 'all',
  confidential: null,
  group_id: 1,
};

export const MOCK_GROUP = {
  name: 'test group',
  full_name: 'full name / test group',
  id: 1,
};

export const MOCK_GROUPS = [
  {
    avatar_url: null,
    name: 'test group',
    full_name: 'full name / test group',
    id: 1,
  },
  {
    avatar_url: 'https://avatar.com',
    name: 'test group 2',
    full_name: 'full name / test group 2',
    id: 2,
  },
];

export const MOCK_PROJECT = {
  name: 'test project',
  namespace: MOCK_GROUP,
  nameWithNamespace: 'test group / test project',
  id: 1,
};

export const MOCK_PROJECTS = [
  {
    name: 'test project',
    namespace: MOCK_GROUP,
    name_with_namespace: 'test group / test project',
    id: 1,
  },
  {
    name: 'test project 2',
    namespace: MOCK_GROUP,
    name_with_namespace: 'test group / test project 2',
    id: 2,
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

export const MOCK_LS_KEY = 'mock-ls-key';
