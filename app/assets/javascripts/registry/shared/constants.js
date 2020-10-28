import { s__, __ } from '~/locale';

export const FETCH_SETTINGS_ERROR_MESSAGE = s__(
  'ContainerRegistry|Something went wrong while fetching the cleanup policy.',
);

export const UPDATE_SETTINGS_ERROR_MESSAGE = s__(
  'ContainerRegistry|Something went wrong while updating the cleanup policy.',
);

export const UPDATE_SETTINGS_SUCCESS_MESSAGE = s__(
  'ContainerRegistry|Cleanup policy successfully saved.',
);

export const NAME_REGEX_LENGTH = 255;

export const ENABLED_TEXT = __('Enabled');
export const DISABLED_TEXT = __('Disabled');

export const ENABLE_TOGGLE_LABEL = s__('ContainerRegistry|Cleanup policy:');
export const ENABLE_TOGGLE_DESCRIPTION = s__(
  'ContainerRegistry|%{toggleStatus} - Tags matching the patterns defined below will be scheduled for deletion',
);

export const TEXT_AREA_INVALID_FEEDBACK = s__(
  'ContainerRegistry|The value of this input should be less than 256 characters',
);

export const EXPIRATION_INTERVAL_LABEL = s__('ContainerRegistry|Expiration interval:');
export const EXPIRATION_SCHEDULE_LABEL = s__('ContainerRegistry|Expiration schedule:');
export const KEEP_N_LABEL = s__('ContainerRegistry|Number of tags to retain:');
export const NAME_REGEX_LABEL = s__(
  'ContainerRegistry|Tags with names matching this regex pattern will %{italicStart}expire:%{italicEnd}',
);
export const NAME_REGEX_PLACEHOLDER = '';
export const NAME_REGEX_DESCRIPTION = s__(
  'ContainerRegistry|Wildcards such as %{codeStart}.*-test%{codeEnd} or %{codeStart}dev-.*%{codeEnd} are supported. To select all tags, use %{codeStart}.*%{codeEnd}',
);
export const NAME_REGEX_KEEP_LABEL = s__(
  'ContainerRegistry|Tags with names matching this regex pattern will %{italicStart}be preserved:%{italicEnd}',
);
export const NAME_REGEX_KEEP_PLACEHOLDER = '';
export const NAME_REGEX_KEEP_DESCRIPTION = s__(
  'ContainerRegistry|Wildcards such as %{codeStart}.*-master%{codeEnd} or %{codeStart}release-.*%{codeEnd} are supported',
);

export const KEEP_N_OPTIONS = [
  { variable: 1, key: 'ONE_TAG', default: false },
  { variable: 5, key: 'FIVE_TAGS', default: false },
  { variable: 10, key: 'TEN_TAGS', default: true },
  { variable: 25, key: 'TWENTY_FIVE_TAGS', default: false },
  { variable: 50, key: 'FIFTY_TAGS', default: false },
  { variable: 100, key: 'ONE_HUNDRED_TAGS', default: false },
];

export const CADENCE_OPTIONS = [
  { key: 'EVERY_DAY', label: __('Every day'), default: true },
  { key: 'EVERY_WEEK', label: __('Every week'), default: false },
  { key: 'EVERY_TWO_WEEKS', label: __('Every two weeks'), default: false },
  { key: 'EVERY_MONTH', label: __('Every month'), default: false },
  { key: 'EVERY_THREE_MONTHS', label: __('Every three months'), default: false },
];

export const OLDER_THAN_OPTIONS = [
  { key: 'SEVEN_DAYS', variable: 7, default: false },
  { key: 'FOURTEEN_DAYS', variable: 14, default: false },
  { key: 'THIRTY_DAYS', variable: 30, default: false },
  { key: 'NINETY_DAYS', variable: 90, default: true },
];
