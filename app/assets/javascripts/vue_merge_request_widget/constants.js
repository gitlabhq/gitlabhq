import { s__ } from '~/locale';

export const SUCCESS = 'success';
export const WARNING = 'warning';
export const DANGER = 'danger';
export const INFO = 'info';
export const CONFIRM = 'confirm';

export const MWPS_MERGE_STRATEGY = 'merge_when_pipeline_succeeds';
export const MTWPS_MERGE_STRATEGY = 'add_to_merge_train_when_pipeline_succeeds';
export const MT_MERGE_STRATEGY = 'merge_train';

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
