import { s__ } from '~/locale';
import { stateToComponentMap as classStateMap, stateKey } from './stores/state_maps';

export const SUCCESS = 'success';
export const WARNING = 'warning';
export const DANGER = 'danger';
export const INFO = 'info';
export const CONFIRM = 'confirm';

export const MWPS_MERGE_STRATEGY = 'merge_when_pipeline_succeeds';
export const MTWPS_MERGE_STRATEGY = 'add_to_merge_train_when_pipeline_succeeds';
export const MT_MERGE_STRATEGY = 'merge_train';

export const PIPELINE_FAILED_STATE = 'failed';

export const AUTO_MERGE_STRATEGIES = [MWPS_MERGE_STRATEGY, MTWPS_MERGE_STRATEGY, MT_MERGE_STRATEGY];

// SP - "Suggest Pipelines"
export const SP_TRACK_LABEL = 'no_pipeline_noticed';
export const SP_LINK_TRACK_EVENT = 'click_link';
export const SP_SHOW_TRACK_EVENT = 'click_button';
export const SP_LINK_TRACK_VALUE = 30;
export const SP_SHOW_TRACK_VALUE = 10;
export const SP_HELP_CONTENT = s__(
  `mrWidget|Use %{linkStart}CI pipelines to test your code%{linkEnd} by simply adding a GitLab CI configuration file to your project. It only takes a minute to make your code more secure and robust.`,
);
export const SP_HELP_URL = 'https://about.gitlab.com/blog/2019/07/12/guide-to-ci-cd-pipelines/';
export const SP_ICON_NAME = 'status_notfound';

export const MERGE_ACTIVE_STATUS_PHRASES = [
  {
    message: s__('mrWidget|Merging! Drum roll, please…'),
    emoji: 'drum',
  },
  {
    message: s__("mrWidget|Merging! We're almost there…"),
    emoji: 'sparkles',
  },
  {
    message: s__('mrWidget|Merging! Changes will land soon…'),
    emoji: 'airplane_arriving',
  },
  {
    message: s__('mrWidget|Merging! Changes are being shipped…'),
    emoji: 'ship',
  },
  {
    message: s__("mrWidget|Merging! Everything's good…"),
    emoji: 'relieved',
  },
  {
    message: s__('mrWidget|Merging! This is going to be great…'),
    emoji: 'heart_eyes',
  },
];

const STATE_MACHINE = {
  states: {
    IDLE: 'IDLE',
    MERGING: 'MERGING',
  },
  transitions: {
    MERGE: 'start-merge',
    MERGE_FAILURE: 'merge-failed',
    MERGED: 'merge-done',
  },
};
const { states, transitions } = STATE_MACHINE;

STATE_MACHINE.definition = {
  initial: states.IDLE,
  states: {
    [states.IDLE]: {
      on: {
        [transitions.MERGE]: states.MERGING,
      },
    },
    [states.MERGING]: {
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
};
export const stateToComponentMap = {
  [states.MERGING]: classStateMap[stateKey.merging],
};

export const EXTENSION_ICONS = {
  failed: 'status-failed',
  warning: 'status-alert',
  success: 'status-success',
  neutral: 'status-neutral',
};

export const EXTENSION_ICON_CLASS = {
  [EXTENSION_ICONS.failed]: 'gl-text-red-500',
  [EXTENSION_ICONS.warning]: 'gl-text-orange-500',
  [EXTENSION_ICONS.success]: 'gl-text-green-500',
  [EXTENSION_ICONS.neutral]: 'gl-text-gray-400',
};

export { STATE_MACHINE };
