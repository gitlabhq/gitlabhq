import { __ } from '~/locale';

export const SCOPE_ISSUES = 'issues';
export const SCOPE_MERGE_REQUESTS = 'merge_requests';
export const SCOPE_BLOB = 'blobs';
export const SCOPE_PROJECTS = 'projects';
export const SCOPE_NOTES = 'notes';
export const SCOPE_COMMITS = 'commits';
export const SCOPE_MILESTONES = 'milestones';
export const SCOPE_WIKI_BLOBS = 'wiki_blobs';
export const SCOPE_EPICS = 'epics';
export const SCOPE_USERS = 'users';

export const LABEL_DEFAULT_CLASSES = [
  'gl-flex',
  'gl-flex-row',
  'gl-flex-nowrap',
  'gl-text-gray-900',
];
export const NAV_LINK_DEFAULT_CLASSES = [...LABEL_DEFAULT_CLASSES, 'gl-justify-between'];
export const NAV_LINK_COUNT_DEFAULT_CLASSES = ['gl-text-sm', 'gl-font-normal'];

export const TRACKING_ACTION_CLICK = 'search:filters:click';
export const TRACKING_LABEL_APPLY = 'Apply Filters';
export const TRACKING_LABEL_RESET = 'Reset Filters';

export const SEARCH_TYPE_BASIC = 'basic';
export const SEARCH_TYPE_ADVANCED = 'advanced';
export const SEARCH_TYPE_ZOEKT = 'zoekt';

export const SEARCH_ICON = 'search';

export const ANY_OPTION = {
  id: null,
  name: __('Any'),
  name_with_namespace: __('Any'),
};

export const GROUP_DATA = {
  headerText: __('Filter results by group'),
  queryParam: 'group_id',
  name: 'name',
  fullName: 'full_name',
};

export const PROJECT_DATA = {
  headerText: __('Filter results by project'),
  queryParam: 'project_id',
  name: 'name',
  fullName: 'name_with_namespace',
};

export const EVENT_CLICK_ZOEKT_INCLUDE_FORKS_ON_SEARCH_RESULTS_PAGE =
  'click_zoekt_include_forks_on_search_results_page';

export const EVENT_SELECT_SOURCE_BRANCH_FILTER = 'select_source_branch_filter';

export const EVENT_SELECT_SOURCE_BRANCH_FILTER_ON_MERGE_REQUEST_PAGE =
  'select_source_branch_filter_on_merge_request_page';
