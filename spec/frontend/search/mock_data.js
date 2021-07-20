import { GROUPS_LOCAL_STORAGE_KEY, PROJECTS_LOCAL_STORAGE_KEY } from '~/search/store/constants';
import * as types from '~/search/store/mutation_types';

export const MOCK_QUERY = {
  scope: 'issues',
  state: 'all',
  confidential: null,
  group_id: 1,
};

export const MOCK_GROUP = {
  id: 1,
  name: 'test group',
  full_name: 'full name / test group',
};

export const MOCK_GROUPS = [
  {
    id: 1,
    avatar_url: null,
    name: 'test group',
    full_name: 'full name / test group',
  },
  {
    id: 2,
    avatar_url: 'https://avatar.com',
    name: 'test group 2',
    full_name: 'full name / test group 2',
  },
];

export const MOCK_PROJECT = {
  id: 1,
  name: 'test project',
  namespace: MOCK_GROUP,
  nameWithNamespace: 'test group / test project',
};

export const MOCK_PROJECTS = [
  {
    id: 1,
    name: 'test project',
    namespace: MOCK_GROUP,
    name_with_namespace: 'test group / test project',
  },
  {
    id: 2,
    name: 'test project 2',
    namespace: MOCK_GROUP,
    name_with_namespace: 'test group / test project 2',
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

export const MOCK_INFLATED_DATA = [
  { id: 1, name: 'test 1' },
  { id: 2, name: 'test 2' },
];

export const FRESH_STORED_DATA = [
  { id: 1, name: 'test 1', frequency: 1 },
  { id: 2, name: 'test 2', frequency: 2 },
];

export const STALE_STORED_DATA = [
  { id: 1, name: 'blah 1', frequency: 1 },
  { id: 2, name: 'blah 2', frequency: 2 },
];

export const MOCK_FRESH_DATA_RES = { name: 'fresh' };

export const PROMISE_ALL_EXPECTED_MUTATIONS = {
  initGroups: {
    type: types.LOAD_FREQUENT_ITEMS,
    payload: { key: GROUPS_LOCAL_STORAGE_KEY, data: FRESH_STORED_DATA },
  },
  resGroups: {
    type: types.LOAD_FREQUENT_ITEMS,
    payload: { key: GROUPS_LOCAL_STORAGE_KEY, data: [MOCK_FRESH_DATA_RES, MOCK_FRESH_DATA_RES] },
  },
  initProjects: {
    type: types.LOAD_FREQUENT_ITEMS,
    payload: { key: PROJECTS_LOCAL_STORAGE_KEY, data: FRESH_STORED_DATA },
  },
  resProjects: {
    type: types.LOAD_FREQUENT_ITEMS,
    payload: { key: PROJECTS_LOCAL_STORAGE_KEY, data: [MOCK_FRESH_DATA_RES, MOCK_FRESH_DATA_RES] },
  },
};
