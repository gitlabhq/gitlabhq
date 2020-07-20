import { s__, __ } from '~/locale';

export const SET_CLEANUP_POLICY_BUTTON = s__('ContainerRegistry|Set cleanup policy');
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
