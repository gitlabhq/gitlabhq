/**
 * Important note: These regex patterns need to use Ruby format because the underlying Pact mock service is written in Ruby.
 */
export const URL = '^(http|https)://[a-z0-9]+([-.]{1}[a-z0-9]+)*.[a-z]{2,5}(:[0-9]{1,5})?(/.*)?$';
export const URL_PATH = '^/[a-zA-Z0-9#-=?_]+$';
export const REDIRECT_HTML = 'You are being <a href=\\"(.)+\\">redirected</a>.';

// Pipelines
export const PIPELINE_GROUPS =
  '^(canceled|created|failed|manual|pending|preparing|running|scheduled|skipped|success|success_warning|waiting-for-resource)$';
export const PIPELINE_LABELS =
  '^(canceled|created|delayed|failed|manual action|passed|pending|preparing|running|skipped|passed with warnings|waiting for resource)$';
export const PIPELINE_SOURCES =
  '^(push|web|trigger|schedule|api|external|pipeline|chat|webide|merge_request_event|external_pull_request_event|parent_pipeline|ondemand_dast_scan|ondemand_dast_validation)$';
export const PIPELINE_STATUSES =
  '^status_(canceled|created|failed|manual|pending|preparing|running|scheduled|skipped|success|warning)$';
export const PIPELINE_TEXTS =
  '^(Canceled|Created|Delayed|Failed|Manual|Passed|Pending|Preparing|Running|Skipped|Waiting)$';

// Jobs
export const JOB_STATUSES =
  '^(CANCELED|CREATED|FAILED|MANUAL|PENDING|PREPARING|RUNNING|SCHEDULED|SKIPPED|SUCCESS|WAITING_FOR_RESOURCE)$';

// Users
export const USER_STATES = '^(active|blocked)$';
