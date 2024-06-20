import { statusFilterData } from '~/search/sidebar/components/status_filter/data';
import { confidentialFilterData } from '~/search/sidebar/components/confidentiality_filter/data';
import { languageFilterData } from '~/search/sidebar/components/language_filter/data';
import { labelFilterData } from '~/search/sidebar/components/label_filter/data';
import { archivedFilterData } from '~/search/sidebar/components/archived_filter/data';
import { INCLUDE_FORKED_FILTER_PARAM } from '~/search/sidebar/components/forks_filter/index.vue';

export const MAX_FREQUENT_ITEMS = 5;

export const MAX_FREQUENCY = 5;

export const GROUPS_LOCAL_STORAGE_KEY = 'global-search-frequent-groups';

export const PROJECTS_LOCAL_STORAGE_KEY = 'global-search-frequent-projects';

export const SIDEBAR_PARAMS = [
  statusFilterData.filterParam,
  confidentialFilterData.filterParam,
  languageFilterData.filterParam,
  labelFilterData.filterParam,
  archivedFilterData.filterParam,
  INCLUDE_FORKED_FILTER_PARAM,
];

export const REGEX_PARAM = 'regex';

export const NUMBER_FORMATING_OPTIONS = { notation: 'compact', compactDisplay: 'short' };

export const ICON_MAP = {
  blobs: 'code',
  issues: 'issues',
  epics: 'epic',
  merge_requests: 'merge-request',
  commits: 'commit',
  notes: 'comments',
  milestones: 'milestone',
  users: 'users',
  projects: 'project',
  wiki_blobs: 'book',
  snippet_titles: 'snippet',
};

export const ZOEKT_SEARCH_TYPE = 'zoekt';
export const ADVANCED_SEARCH_TYPE = 'advanced';
export const BASIC_SEARCH_TYPE = 'basic';

export const SEARCH_LEVEL_GLOBAL = 'global';
export const SEARCH_LEVEL_PROJECT = 'project';
export const SEARCH_LEVEL_GROUP = 'group';

export const LS_REGEX_HANDLE = `${REGEX_PARAM}_advanced_search`;
