import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { DOCS_URL_IN_EE_DIR } from 'jh_else_ce/lib/utils/url_utility';
import { stateToComponentMap as classStateMap, stateKey } from './stores/state_maps';

export const FOUR_MINUTES_IN_MS = 1000 * 60 * 4;

export const STATE_QUERY_POLLING_INTERVAL_DEFAULT = 5000;
export const STATE_QUERY_POLLING_INTERVAL_BACKOFF = 1.2;

export const SUCCESS = 'success';
export const WARNING = 'warning';
export const INFO = 'info';

export const MWPS_MERGE_STRATEGY = 'merge_when_pipeline_succeeds';
export const MWCP_MERGE_STRATEGY = 'merge_when_checks_pass';
export const MTWPS_MERGE_STRATEGY = 'add_to_merge_train_when_pipeline_succeeds';
export const MTWCP_MERGE_STRATEGY = 'add_to_merge_train_when_checks_pass';
export const MT_MERGE_STRATEGY = 'merge_train';

export const PIPELINE_FAILED_STATE = 'failed';

export const AUTO_MERGE_STRATEGIES = [
  MWPS_MERGE_STRATEGY,
  MTWPS_MERGE_STRATEGY,
  MTWCP_MERGE_STRATEGY,
  MT_MERGE_STRATEGY,
  MWCP_MERGE_STRATEGY,
];

// SP - "Suggest Pipelines"
export const SP_TRACK_LABEL = 'no_pipeline_noticed';
export const SP_SHOW_TRACK_EVENT = 'click_button';
export const SP_SHOW_TRACK_VALUE = 10;
export const SP_HELP_CONTENT = s__(
  `mrWidget|GitLab %{linkStart}CI/CD can automatically build, test, and deploy your application.%{linkEnd} It only takes a few minutes to get started, and we can help you create a pipeline configuration file.`,
);
export const SP_HELP_URL = `${DOCS_URL_IN_EE_DIR}/ci/quick_start/`;
export const SP_ICON_NAME = 'status_notfound';

// JM - "Jenkins Migration"
export const JM_JENKINS_TITLE_ICON_NAME = 'information';
export const JM_EVENT_NAME = 'click_dismiss_button_jenkins_migration_callout';
export const JM_MIGRATION_LINK = helpPagePath('ci/migration/jenkins.md');

export const MERGE_ACTIVE_STATUS_PHRASES = [
  {
    message: s__('mrWidget|%{boldStart}Merging!%{boldEnd} Drum roll, please…'),
    emoji: 'drum',
  },
  {
    message: s__("mrWidget|%{boldStart}Merging!%{boldEnd} We're almost there…"),
    emoji: 'sparkles',
  },
  {
    message: s__('mrWidget|%{boldStart}Merging!%{boldEnd} Changes will land soon…'),
    emoji: 'airplane_arriving',
  },
  {
    message: s__('mrWidget|%{boldStart}Merging!%{boldEnd} Changes are being shipped…'),
    emoji: 'ship',
  },
  {
    message: s__("mrWidget|%{boldStart}Merging!%{boldEnd} Everything's good…"),
    emoji: 'relieved',
  },
  {
    message: s__('mrWidget|%{boldStart}Merging!%{boldEnd} This is going to be great…'),
    emoji: 'heart_eyes',
  },
  {
    message: s__('mrWidget|%{boldStart}Merging!%{boldEnd} Lift-off in 5… 4… 3…'),
    emoji: 'rocket',
  },
  {
    message: s__('mrWidget|%{boldStart}Merging!%{boldEnd} The changes are leaving the station…'),
    emoji: 'bullettrain_front',
  },
  {
    message: s__('mrWidget|%{boldStart}Merging!%{boldEnd} Take a deep breath and relax…'),
    emoji: 'sunglasses',
  },
];

const STATE_MACHINE = {
  states: {
    IDLE: 'IDLE',
    MERGING: 'MERGING',
    MERGED: 'MERGED',
    AUTO_MERGE: 'AUTO_MERGE',
  },
  transitions: {
    MERGE: 'start-merge',
    AUTO_MERGE: 'start-auto-merge',
    MERGE_FAILURE: 'merge-failed',
    MERGED: 'merge-done',
    MERGING: 'merging',
  },
};
const { states, transitions } = STATE_MACHINE;

STATE_MACHINE.definition = {
  initial: states.IDLE,
  states: {
    [states.IDLE]: {
      on: {
        [transitions.MERGE]: states.MERGING,
        [transitions.AUTO_MERGE]: states.AUTO_MERGE,
        [transitions.MERGING]: states.MERGING,
      },
    },
    [states.MERGING]: {
      on: {
        [transitions.MERGED]: states.MERGED,
        [transitions.MERGE_FAILURE]: states.IDLE,
      },
    },
    [states.AUTO_MERGE]: {
      on: {
        [transitions.MERGED]: states.IDLE,
        [transitions.MERGE_FAILURE]: states.IDLE,
      },
    },
  },
};

export const stateToTransitionMap = {
  [stateKey.merging]: transitions.MERGE,
  [stateKey.merged]: transitions.MERGED,
  [stateKey.autoMergeEnabled]: transitions.AUTO_MERGE,
};
export const stateToComponentMap = {
  [states.MERGING]: classStateMap[stateKey.merging],
  [states.MERGED]: classStateMap[stateKey.merged],
  [states.AUTO_MERGE]: classStateMap[stateKey.autoMergeEnabled],
};

export const EXTENSION_ICONS = {
  failed: 'failed',
  warning: 'warning',
  success: 'success',
  neutral: 'neutral',
  error: 'error',
  notice: 'notice',
  severityCritical: 'severityCritical',
  severityHigh: 'severityHigh',
  severityMedium: 'severityMedium',
  severityLow: 'severityLow',
  severityInfo: 'severityInfo',
  severityUnknown: 'severityUnknown',
};

export const EXTENSION_ICON_NAMES = {
  failed: 'status-failed',
  warning: 'status-alert',
  success: 'status-success',
  neutral: 'status-neutral',
  error: 'status-alert',
  notice: 'status-alert',
  scheduled: 'status-scheduled',
  severityCritical: 'severity-critical',
  severityHigh: 'severity-high',
  severityMedium: 'severity-medium',
  severityLow: 'severity-low',
  severityInfo: 'severity-info',
  severityUnknown: 'severity-unknown',
};

export const EXTENSION_ICON_CLASS = {
  failed: {
    backgroundClass: 'gl-bg-status-danger',
    iconClass: 'gl-fill-status-danger',
  },
  warning: {
    backgroundClass: 'gl-bg-status-warning',
    iconClass: 'gl-fill-status-warning',
  },
  success: {
    backgroundClass: 'gl-bg-status-success',
    iconClass: 'gl-fill-status-success',
  },
  neutral: {
    backgroundClass: 'gl-bg-status-neutral',
    iconClass: 'gl-fill-status-neutral',
  },
  error: {
    backgroundClass: 'gl-bg-status-danger',
    iconClass: 'gl-fill-status-danger',
  },
  notice: {
    backgroundClass: 'gl-bg-status-neutral',
    iconClass: 'gl-fill-status-neutral',
  },
  scheduled: {
    backgroundClass: 'gl-bg-status-info',
    iconClass: 'gl-fill-status-info',
  },
  severityCritical: {
    backgroundClass: 'gl-bg-red-100',
    iconClass: 'gl-fill-red-800',
  },
  severityHigh: {
    backgroundClass: 'gl-bg-red-100',
    iconClass: 'gl-fill-red-600',
  },
  severityMedium: {
    backgroundClass: 'gl-bg-orange-100',
    iconClass: 'gl-fill-orange-400',
  },
  severityLow: {
    backgroundClass: 'gl-bg-orange-100',
    iconClass: 'gl-fill-orange-300',
  },
  severityInfo: {
    backgroundClass: 'gl-bg-status-info',
    iconClass: 'gl-fill-status-info',
  },
  severityUnknown: {
    backgroundClass: 'gl-bg-status-neutral',
    iconClass: 'gl-fill-status-neutral',
  },
};

export const VIEW_MERGE_REQUEST_WIDGET = 'view_merge_request_widget';
export const EXPAND_MERGE_REQUEST_WIDGET = 'expand_merge_request_widget';
export const CLICK_FULL_REPORT_ON_MERGE_REQUEST_WIDGET =
  'click_full_report_on_merge_request_widget';

export { STATE_MACHINE };

export const INVALID_RULES_DOCS_PATH = helpPagePath(
  'user/project/merge_requests/approvals/_index.md',
  {
    anchor: 'invalid-rules',
  },
);

export const DETAILED_MERGE_STATUS = {
  PREPARING: 'PREPARING',
  MERGEABLE: 'MERGEABLE',
  CHECKING: 'CHECKING',
  NOT_OPEN: 'NOT_OPEN',
  DISCUSSIONS_NOT_RESOLVED: 'DISCUSSIONS_NOT_RESOLVED',
  NOT_APPROVED: 'NOT_APPROVED',
  DRAFT_STATUS: 'DRAFT_STATUS',
  BLOCKED_STATUS: 'BLOCKED_STATUS',
  CI_MUST_PASS: 'CI_MUST_PASS',
  CI_STILL_RUNNING: 'CI_STILL_RUNNING',
  EXTERNAL_STATUS_CHECKS: 'EXTERNAL_STATUS_CHECKS',
};

export const MT_SKIP_TRAIN = 'skip';
export const MT_RESTART_TRAIN = 'restart';

// Pipeline event type names

export const PIPELINE_EVENT_TYPE_MERGE_TRAIN = 'Merge train pipeline';
export const PIPELINE_EVENT_TYPE_MERGED_RESULT = 'Merged results pipeline';
export const PIPELINE_EVENT_TYPE_MERGE_REQUEST = 'Merge request pipeline';

export const PIPELINE_EVENT_TYPE_MAP = {
  [PIPELINE_EVENT_TYPE_MERGE_TRAIN]: {
    title: s__('Pipeline|What is a merge train pipeline?'),
    content: s__(
      'Pipeline|Merge train pipeline runs on the contents of the merge request combined with the contents of all other merge requests queued for merging into the target branch.',
    ),
  },
  [PIPELINE_EVENT_TYPE_MERGED_RESULT]: {
    title: s__('Pipeline|What is a merged results pipeline?'),
    content: s__(
      'Pipeline|Merged results pipeline runs on the contents of the merge request combined with the contents of the target branch.',
    ),
  },
  [PIPELINE_EVENT_TYPE_MERGE_REQUEST]: {
    title: s__('Pipeline|What is a merge request pipeline?'),
    content: s__(
      "Pipeline|Merge request pipeline runs on the contents of the merge request's source branch, not the target branch.",
    ),
  },
};
