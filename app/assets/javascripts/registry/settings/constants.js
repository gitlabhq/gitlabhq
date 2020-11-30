import { s__, __ } from '~/locale';

export const SET_CLEANUP_POLICY_BUTTON = __('Save');
export const CLEANUP_POLICY_CARD_HEADER = s__('ContainerRegistry|Tag expiration policy');
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
  'ContainerRegistry|Tags that match these rules will always be %{strongStart}kept%{strongEnd}, even if they match a removal rule below. The %{secondStrongStart}latest%{secondStrongEnd} tag will always be kept.',
);
export const KEEP_N_LABEL = s__('ContainerRegistry|Keep the most recent:');
export const NAME_REGEX_KEEP_LABEL = s__('ContainerRegistry|Keep tags matching:');
export const NAME_REGEX_KEEP_PLACEHOLDER = 'production-v.*';
export const NAME_REGEX_KEEP_DESCRIPTION = s__(
  'ContainerRegistry|Tags with names matching this regex pattern will be kept. %{linkStart}More information%{linkEnd}',
);

export const REMOVE_HEADER_TEXT = s__('ContainerRegistry|Remove these tags');
export const REMOVE_INFO_TEXT = s__(
  'ContainerRegistry|Tags that match these rules will be %{strongStart}removed%{strongEnd}, unless kept by a rule above.',
);
export const EXPIRATION_SCHEDULE_LABEL = s__('ContainerRegistry|Remove tags older than:');
export const NAME_REGEX_LABEL = s__('ContainerRegistry|Remove tags matching:');
export const NAME_REGEX_PLACEHOLDER = '.*';
export const NAME_REGEX_DESCRIPTION = s__(
  'ContainerRegistry|Tags with names matching this regex pattern will be removed. %{linkStart}More information%{linkEnd}',
);

export const ENABLED_TEXT = __('Enabled');
export const DISABLED_TEXT = __('Disabled');

export const ENABLE_TOGGLE_DESCRIPTION = s__(
  'ContainerRegistry|%{toggleStatus} - Tags matching the rules defined below will be automatically scheduled for deletion.',
);

export const CADENCE_LABEL = s__('ContainerRegistry|Run cleanup every:');

export const NEXT_CLEANUP_LABEL = s__('ContainerRegistry|Next cleanup scheduled to run on:');
export const NOT_SCHEDULED_POLICY_TEXT = s__('ContainerRegistry|Not yet scheduled');
export const EXPIRATION_POLICY_FOOTER_NOTE = s__(
  'ContainerRegistry|Note: Any policy update will result in a change to the scheduled run date and time',
);

export const NAME_REGEX_LENGTH = 255;
