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
  'gl-text-default',
];
export const NAV_LINK_DEFAULT_CLASSES = [...LABEL_DEFAULT_CLASSES, 'gl-justify-between'];
export const NAV_LINK_COUNT_DEFAULT_CLASSES = ['gl-text-sm', 'gl-font-normal'];

export const TRACKING_ACTION_CLICK = 'search:filters:click';
export const TRACKING_LABEL_APPLY = 'Apply Filters';
export const TRACKING_LABEL_RESET = 'Reset Filters';

export const ARCHIVED_TRACKING_NAMESPACE = 'search:archived:select';
export const ARCHIVED_TRACKING_LABEL_CHECKBOX = 'checkbox';
export const ARCHIVED_TRACKING_LABEL_CHECKBOX_LABEL = 'Include archived';

export const SEARCH_TYPE_BASIC = 'basic';
export const SEARCH_TYPE_ADVANCED = 'advanced';
export const SEARCH_TYPE_ZOEKT = 'zoekt';

export const SEARCH_ICON = 'search';
export const USER_ICON = 'user';

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

export const EVENT_SELECT_SOURCE_BRANCH_FILTER_ON_MERGE_REQUEST_PAGE =
  'select_source_branch_filter_on_merge_request_page';

export const EVENT_SELECT_AUTHOR_FILTER_ON_MERGE_REQUEST_PAGE =
  'event_select_author_filter_on_merge_request_page';

export const LANGUAGE_DEFAULT_ITEM_LENGTH = 10;
export const LANGUAGE_MAX_ITEM_LENGTH = 100;

export const INCLUDE_ARCHIVED_FILTER_PARAM = 'include_archived';
export const CONFIDENTAL_FILTER_PARAM = 'confidential';
export const LABEL_FILTER_PARAM = 'label_name';
export const INCLUDE_FORKED_FILTER_PARAM = 'include_forked';
export const LANGUAGE_FILTER_PARAM = 'language';
export const SOURCE_BRANCH_PARAM = 'source_branch';
export const NOT_SOURCE_BRANCH_PARAM = 'not[source_branch]';
export const AUTHOR_PARAM = 'author_username';
export const NOT_AUTHOR_PARAM = 'not[author_username]';

export const FIRST_DROPDOWN_INDEX = 0;
export const SEARCH_BOX_INDEX = 0;
export const SEARCH_INPUT_DESCRIPTION = 'label-search-input-description';
export const SEARCH_RESULTS_DESCRIPTION = 'label-search-results-description';
export const LABEL_FILTER_HEADER = __('Labels');
export const LABEL_AGREGATION_NAME = 'labels';

export const SOURCE_BRANCH_ENDPOINT_PATH = '/-/autocomplete/merge_request_source_branches.json';
export const AUTHOR_ENDPOINT_PATH = '/-/autocomplete/users.json';

export const CONFIDENTIAL_FILTERS = {
  ANY: {
    label: __('Any'),
    value: null,
  },
  CONFIDENTIAL: {
    label: __('Confidential'),
    value: 'yes',
  },
  NOT_CONFIDENTIAL: {
    label: __('Not confidential'),
    value: 'no',
  },
};

export const STATE_FILTER_PARAM = 'state';
export const STATE_FILTERS = {
  ANY: {
    label: __('Any'),
    value: null,
  },
  OPEN: {
    label: __('Open'),
    value: 'opened',
  },
  CLOSED: {
    label: __('Closed'),
    value: 'closed',
  },
  MERGED: {
    label: __('Merged'),
    value: 'merged',
  },
};
