import { s__ } from '~/locale';
import {
  CONFIDENTAL_FILTER_PARAM,
  INCLUDE_ARCHIVED_FILTER_PARAM,
  LABEL_FILTER_PARAM,
  INCLUDE_FORKED_FILTER_PARAM,
  LANGUAGE_FILTER_PARAM,
  SOURCE_BRANCH_PARAM,
  NOT_SOURCE_BRANCH_PARAM,
  STATE_FILTER_PARAM,
} from '~/search/sidebar/constants';

export const MAX_FREQUENT_ITEMS = 5;

export const MAX_FREQUENCY = 5;

export const GROUPS_LOCAL_STORAGE_KEY = 'global-search-frequent-groups';

export const PROJECTS_LOCAL_STORAGE_KEY = 'global-search-frequent-projects';

export const SIDEBAR_PARAMS = [
  STATE_FILTER_PARAM,
  CONFIDENTAL_FILTER_PARAM,
  LANGUAGE_FILTER_PARAM,
  LABEL_FILTER_PARAM,
  INCLUDE_ARCHIVED_FILTER_PARAM,
  INCLUDE_FORKED_FILTER_PARAM,
  SOURCE_BRANCH_PARAM,
  NOT_SOURCE_BRANCH_PARAM,
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

export const SCOPE_NAVIGATION_MAP = {
  blobs: s__(`GlobalSearch|Code`),
  issues: s__(`GlobalSearch|Issues`),
  epics: s__(`GlobalSearch|'Epics`),
  merge_requests: s__(`GlobalSearch|Merge request`),
  commits: s__(`GlobalSearch|Commits`),
  notes: s__(`GlobalSearch|Comments`),
  milestones: s__(`GlobalSearch|Milestones`),
  users: s__(`GlobalSearch|Users`),
  projects: s__(`GlobalSearch|Projects`),
  wiki_blobs: s__(`GlobalSearch|Wiki`),
  snippet_titles: s__(`GlobalSearch|Snippets`),
};

export const ZOEKT_SEARCH_TYPE = 'zoekt';
export const ADVANCED_SEARCH_TYPE = 'advanced';
export const BASIC_SEARCH_TYPE = 'basic';

export const SEARCH_LEVEL_GLOBAL = 'global';
export const SEARCH_LEVEL_PROJECT = 'project';
export const SEARCH_LEVEL_GROUP = 'group';

export const LS_REGEX_HANDLE = `${REGEX_PARAM}_advanced_search`;
