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
  AUTHOR_PARAM,
  NOT_AUTHOR_PARAM,
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
  AUTHOR_PARAM,
  NOT_AUTHOR_PARAM,
];

export const REGEX_PARAM = 'regex';

export const NUMBER_FORMATING_OPTIONS = { notation: 'compact', compactDisplay: 'short' };

export const ICON_MAP = {
  blobs: 'code',
  issues: window.gon?.features?.workItemScopeFrontend ? 'work' : 'issues',
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

export const SUBITEMS_FILTER = {
  issue: { order: 1, icon: 'issue-type-issue', label: s__('GlobalSearch|Issues') },
  epic: { order: 2, icon: 'issue-type-epic', label: s__('GlobalSearch|Epics') },
  task: { order: 3, icon: 'issue-type-task', label: s__('GlobalSearch|Tasks') },
  objective: { order: 4, icon: 'issue-type-objective', label: s__('GlobalSearch|Objectives') },
  key_result: { order: 5, icon: 'issue-type-keyresult', label: s__('GlobalSearch|Key results') },
};

export const SCOPE_NAVIGATION_MAP = {
  blobs: s__('GlobalSearch|Code'),
  issues: window.gon?.features?.workItemScopeFrontend
    ? s__('GlobalSearch|Work items')
    : s__('GlobalSearch|Issues'),
  epics: s__('GlobalSearch|Epics'),
  merge_requests: s__('GlobalSearch|Merge request'),
  commits: s__('GlobalSearch|Commits'),
  notes: s__('GlobalSearch|Comments'),
  milestones: s__('GlobalSearch|Milestones'),
  users: s__('GlobalSearch|Users'),
  projects: s__('GlobalSearch|Projects'),
  wiki_blobs: s__('GlobalSearch|Wiki'),
  snippet_titles: s__('GlobalSearch|Snippets'),
};

export const ZOEKT_SEARCH_TYPE = 'zoekt';
export const ADVANCED_SEARCH_TYPE = 'advanced';
export const BASIC_SEARCH_TYPE = 'basic';

export const SEARCH_LEVEL_GLOBAL = 'global';
export const SEARCH_LEVEL_PROJECT = 'project';
export const SEARCH_LEVEL_GROUP = 'group';

export const LS_REGEX_HANDLE = `${REGEX_PARAM}_advanced_search`;
