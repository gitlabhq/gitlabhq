import { cloneDeep } from 'lodash-es';
import { GROUPS_LOCAL_STORAGE_KEY, PROJECTS_LOCAL_STORAGE_KEY } from './constants';

const createState = ({
  query,
  navigation,
  searchType,
  searchLevel,
  advancedSearchAvailable,
  zoektAvailable,
  groupInitialJson,
  projectInitialJson,
  workItemTypes,
  defaultBranchName,
  repositoryRef,
}) => ({
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
  aggregations: {
    error: false,
    fetching: false,
    data: [],
  },
  workItemTypes: workItemTypes || [],
  searchLabelString: '',
  searchType,
  searchLevel,
  advancedSearchAvailable,
  zoektAvailable,
  groupInitialJson,
  projectInitialJson,
  defaultBranchName,
  repositoryRef,
});

export default createState;
