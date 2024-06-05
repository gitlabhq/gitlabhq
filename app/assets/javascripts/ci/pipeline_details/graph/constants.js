export const DOWNSTREAM = 'downstream';
export const MAIN = 'main';
export const UPSTREAM = 'upstream';

/*
  this value is based on the gl-pipeline-job-width class
  plus some extra for the margins
*/
export const ONE_COL_WIDTH = 180;

export const STAGE_VIEW = 'stage';
export const LAYER_VIEW = 'layer';

export const SKIP_RETRY_MODAL_KEY = 'skip_retry_modal';
export const VIEW_TYPE_KEY = 'pipeline_graph_view_type';

export const SINGLE_JOB = 'single_job';
export const JOB_DROPDOWN = 'job_dropdown';

export const BUILD_KIND = 'BUILD';
export const BRIDGE_KIND = 'BRIDGE';

export const ACTION_FAILURE = 'action_failure';
export const IID_FAILURE = 'missing_iid';

export const RETRY_ACTION_TITLE = 'Retry';
export const MANUAL_ACTION_TITLE = 'Run';

/*
  this poll interval is shared between the graph,
  pipeline header, jobs tab and failed jobs tab to
  keep all the data relatively in sync
*/
export const POLL_INTERVAL = 10000;
