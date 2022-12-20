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

export const PRELOAD_EXPECTED_MUTATIONS = [
  {
    type: types.LOAD_FREQUENT_ITEMS,
    payload: { key: GROUPS_LOCAL_STORAGE_KEY, data: FRESH_STORED_DATA },
  },
  {
    type: types.LOAD_FREQUENT_ITEMS,
    payload: { key: PROJECTS_LOCAL_STORAGE_KEY, data: FRESH_STORED_DATA },
  },
];

export const PROMISE_ALL_EXPECTED_MUTATIONS = {
  resGroups: {
    type: types.LOAD_FREQUENT_ITEMS,
    payload: { key: GROUPS_LOCAL_STORAGE_KEY, data: [MOCK_FRESH_DATA_RES, MOCK_FRESH_DATA_RES] },
  },
  resProjects: {
    type: types.LOAD_FREQUENT_ITEMS,
    payload: { key: PROJECTS_LOCAL_STORAGE_KEY, data: [MOCK_FRESH_DATA_RES, MOCK_FRESH_DATA_RES] },
  },
};

export const MOCK_NAVIGATION = {
  projects: {
    label: 'Projects',
    scope: 'projects',
    link: '/search?scope=projects&search=et',
    count_link: '/search/count?scope=projects&search=et',
    count: '10,000+',
  },
  blobs: {
    label: 'Code',
    scope: 'blobs',
    link: '/search?scope=blobs&search=et',
    count_link: '/search/count?scope=blobs&search=et',
  },
  issues: {
    label: 'Issues',
    scope: 'issues',
    link: '/search?scope=issues&search=et',
    active: true,
    count: '2,430',
  },
  merge_requests: {
    label: 'Merge requests',
    scope: 'merge_requests',
    link: '/search?scope=merge_requests&search=et',
    count_link: '/search/count?scope=merge_requests&search=et',
  },
  wiki_blobs: {
    label: 'Wiki',
    scope: 'wiki_blobs',
    link: '/search?scope=wiki_blobs&search=et',
    count_link: '/search/count?scope=wiki_blobs&search=et',
  },
  commits: {
    label: 'Commits',
    scope: 'commits',
    link: '/search?scope=commits&search=et',
    count_link: '/search/count?scope=commits&search=et',
  },
  notes: {
    label: 'Comments',
    scope: 'notes',
    link: '/search?scope=notes&search=et',
    count_link: '/search/count?scope=notes&search=et',
  },
  milestones: {
    label: 'Milestones',
    scope: 'milestones',
    link: '/search?scope=milestones&search=et',
    count_link: '/search/count?scope=milestones&search=et',
  },
  users: {
    label: 'Users',
    scope: 'users',
    link: '/search?scope=users&search=et',
    count_link: '/search/count?scope=users&search=et',
  },
};

export const MOCK_NAVIGATION_DATA = {
  projects: {
    label: 'Projects',
    scope: 'projects',
    link: '/search?scope=projects&search=et',
    count_link: '/search/count?scope=projects&search=et',
  },
};

export const MOCK_ENDPOINT_RESPONSE = { count: '13' };

export const MOCK_DATA_FOR_NAVIGATION_ACTION_MUTATION = {
  projects: {
    count: '13',
    label: 'Projects',
    scope: 'projects',
    link: '/search?scope=projects&search=et',
    count_link: '/search/count?scope=projects&search=et',
  },
};

export const MOCK_NAVIGATION_ACTION_MUTATION = {
  type: types.RECEIVE_NAVIGATION_COUNT,
  payload: { key: 'projects', count: '13' },
};
