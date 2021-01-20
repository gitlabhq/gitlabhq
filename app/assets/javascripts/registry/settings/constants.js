import { s__, __ } from '~/locale';

export const SET_CLEANUP_POLICY_BUTTON = __('Save');
export const UNAVAILABLE_FEATURE_TITLE = s__(
  `ContainerRegistry|Cleanup policy for tags is disabled`,
);
export const UNAVAILABLE_FEATURE_INTRO_TEXT = s__(
  `ContainerRegistry|This project's cleanup policy for tags is not enabled.`,
);
export const UNAVAILABLE_USER_FEATURE_TEXT = __(`Please contact your administrator.`);
export const UNAVAILABLE_ADMIN_FEATURE_TEXT = s__(
  `ContainerRegistry| Please visit the %{linkStart}administration settings%{linkEnd} to enable this feature.`,
);

export const TEXT_AREA_INVALID_FEEDBACK = s__(
  'ContainerRegistry|The value of this input should be less than 256 characters',
);

export const KEEP_HEADER_TEXT = s__('ContainerRegistry|Keep these tags');
export const KEEP_INFO_TEXT = s__(
  'ContainerRegistry|Tags that match these rules are %{strongStart}kept%{strongEnd}, even if they match a removal rule below. The %{secondStrongStart}latest%{secondStrongEnd} tag is always kept.',
);
export const KEEP_N_LABEL = s__('ContainerRegistry|Keep the most recent:');
export const NAME_REGEX_KEEP_LABEL = s__('ContainerRegistry|Keep tags matching:');
export const NAME_REGEX_KEEP_DESCRIPTION = s__(
  'ContainerRegistry|Tags with names that match this regex pattern are kept. %{linkStart}View regex examples.%{linkEnd}',
);

export const REMOVE_HEADER_TEXT = s__('ContainerRegistry|Remove these tags');
export const REMOVE_INFO_TEXT = s__(
  'ContainerRegistry|Tags that match these rules are %{strongStart}removed%{strongEnd}, unless a rule above says to keep them.',
);
export const EXPIRATION_SCHEDULE_LABEL = s__('ContainerRegistry|Remove tags older than:');
export const NAME_REGEX_LABEL = s__('ContainerRegistry|Remove tags matching:');
export const NAME_REGEX_PLACEHOLDER = '.*';
export const NAME_REGEX_DESCRIPTION = s__(
  'ContainerRegistry|Tags with names that match this regex pattern are removed. %{linkStart}View regex examples.%{linkEnd}',
);

export const ENABLED_TOGGLE_DESCRIPTION = s__(
  'ContainerRegistry|%{strongStart}Enabled%{strongEnd} - Tags that match the rules on this page are automatically scheduled for deletion.',
);
export const DISABLED_TOGGLE_DESCRIPTION = s__(
  'ContainerRegistry|%{strongStart}Disabled%{strongEnd} - Tags will not be automatically deleted.',
);

export const CADENCE_LABEL = s__('ContainerRegistry|Run cleanup:');

export const NEXT_CLEANUP_LABEL = s__('ContainerRegistry|Next cleanup scheduled to run on:');
export const NOT_SCHEDULED_POLICY_TEXT = s__('ContainerRegistry|Not yet scheduled');
export const EXPIRATION_POLICY_FOOTER_NOTE = s__(
  'ContainerRegistry|Note: Any policy update will result in a change to the scheduled run date and time',
);

export const KEEP_N_OPTIONS = [
  { key: 'ONE_TAG', variable: 1, default: false },
  { key: 'FIVE_TAGS', variable: 5, default: false },
  { key: 'TEN_TAGS', variable: 10, default: true },
  { key: 'TWENTY_FIVE_TAGS', variable: 25, default: false },
  { key: 'FIFTY_TAGS', variable: 50, default: false },
  { key: 'ONE_HUNDRED_TAGS', variable: 100, default: false },
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
