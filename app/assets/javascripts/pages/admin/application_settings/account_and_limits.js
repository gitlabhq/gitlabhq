import { __ } from '~/locale';

export const PLACEHOLDER_USER_EXTERNAL_DEFAULT_TRUE = __('Regex pattern');
export const PLACEHOLDER_USER_EXTERNAL_DEFAULT_FALSE = __(
  'To define internal users, first enable new users set to external',
);

function setUserInternalRegexPlaceholder(checkbox) {
  const userInternalRegex = document.getElementById(
    'application_setting_user_default_internal_regex',
  );
  if (checkbox && userInternalRegex) {
    if (checkbox.checked) {
      userInternalRegex.readOnly = false;
      userInternalRegex.placeholder = PLACEHOLDER_USER_EXTERNAL_DEFAULT_TRUE;
    } else {
      userInternalRegex.readOnly = true;
      userInternalRegex.placeholder = PLACEHOLDER_USER_EXTERNAL_DEFAULT_FALSE;
    }
  }
}

export default function initUserInternalRegexPlaceholder() {
  const checkbox = document.getElementById('application_setting_user_default_external');
  setUserInternalRegexPlaceholder(checkbox);
  checkbox.addEventListener('change', () => {
    setUserInternalRegexPlaceholder(checkbox);
  });
}
