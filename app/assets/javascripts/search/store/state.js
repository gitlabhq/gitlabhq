import { cloneDeep } from 'lodash';
import { GROUPS_LOCAL_STORAGE_KEY, PROJECTS_LOCAL_STORAGE_KEY } from './constants';

const createState = ({ query, navigation, useSidebarNavigation }) => ({
  urlQuery: cloneDeep(query),
  query,
  groups: [],
  fetchingGroups: false,
  projects: [],
  fetchingProjects: false,
  frequentItems: {
    [GROUPS_LOCAL_STORAGE_KEY]: [],
    [PROJECTS_LOCAL_STORAGE_KEY]: [],
  },
  sidebarDirty: false,
  navigation,
  useSidebarNavigation,
  aggregations: {
    error: false,
    fetching: false,
    data: [],
  },
  searchLabelString: '',
});

export default createState;
