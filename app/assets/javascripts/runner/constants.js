import { s__ } from '~/locale';

export const RUNNER_PAGE_SIZE = 20;
export const RUNNER_JOB_COUNT_LIMIT = 1000;

export const I18N_FETCH_ERROR = s__('Runners|Something went wrong while fetching runner data.');
export const I18N_DETAILS_TITLE = s__('Runners|Runner #%{runner_id}');

export const RUNNER_TAG_BADGE_VARIANT = 'info';
export const RUNNER_TAG_BG_CLASS = 'gl-bg-blue-100';

// Filtered search parameter names
// - Used for URL params names
// - GlFilteredSearch tokens type

export const PARAM_KEY_STATUS = 'status';
export const PARAM_KEY_RUNNER_TYPE = 'runner_type';
export const PARAM_KEY_TAG = 'tag';
export const PARAM_KEY_SEARCH = 'search';

export const PARAM_KEY_SORT = 'sort';
export const PARAM_KEY_PAGE = 'page';
export const PARAM_KEY_AFTER = 'after';
export const PARAM_KEY_BEFORE = 'before';

// CiRunnerType

export const INSTANCE_TYPE = 'INSTANCE_TYPE';
export const GROUP_TYPE = 'GROUP_TYPE';
export const PROJECT_TYPE = 'PROJECT_TYPE';

// CiRunnerStatus

export const STATUS_ACTIVE = 'ACTIVE';
export const STATUS_PAUSED = 'PAUSED';
export const STATUS_ONLINE = 'ONLINE';
export const STATUS_OFFLINE = 'OFFLINE';
export const STATUS_NOT_CONNECTED = 'NOT_CONNECTED';

// CiRunnerAccessLevel

export const ACCESS_LEVEL_NOT_PROTECTED = 'NOT_PROTECTED';
export const ACCESS_LEVEL_REF_PROTECTED = 'REF_PROTECTED';

// CiRunnerSort

export const CREATED_DESC = 'CREATED_DESC';
export const CREATED_ASC = 'CREATED_ASC'; // TODO Add this to the API
export const CONTACTED_DESC = 'CONTACTED_DESC'; // TODO Add this to the API
export const CONTACTED_ASC = 'CONTACTED_ASC';

export const DEFAULT_SORT = CREATED_DESC;
