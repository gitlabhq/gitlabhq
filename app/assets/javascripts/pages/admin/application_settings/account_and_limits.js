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

function initUserInternalRegexPlaceholder() {
  const checkbox = document.getElementById('application_setting_user_default_external');
  setUserInternalRegexPlaceholder(checkbox);
  checkbox.addEventListener('change', () => {
    setUserInternalRegexPlaceholder(checkbox);
  });
}

/**
 * Sets up logic inside "Dormant users" subsection:
 * - checkbox enables/disables additional input
 * - shows/hides an inline error on input validation
 */
function initDeactivateDormantUsersPeriodInputSection() {
  const DISPLAY_NONE_CLASS = 'gl-display-none';

  /** @type {HTMLInputElement} */
  const checkbox = document.getElementById('application_setting_deactivate_dormant_users');
  /** @type {HTMLInputElement} */
  const input = document.getElementById('application_setting_deactivate_dormant_users_period');
  /** @type {HTMLDivElement} */
  const errorLabel = document.getElementById(
    'application_setting_deactivate_dormant_users_period_error',
  );

  if (!checkbox || !input || !errorLabel) return;

  const hideInputErrorLabel = () => {
    if (input.checkValidity()) {
      errorLabel.classList.add(DISPLAY_NONE_CLASS);
    }
  };

  const handleInputInvalidState = (event) => {
    event.preventDefault();
    event.stopImmediatePropagation();
    errorLabel.classList.remove(DISPLAY_NONE_CLASS);
    return false;
  };

  const updateInputDisabledState = () => {
    input.disabled = !checkbox.checked;
    if (input.disabled) {
      hideInputErrorLabel();
    }
  };

  // Show error when input is invalid
  input.addEventListener('invalid', handleInputInvalidState);
  // Hide error when input changes
  input.addEventListener('input', hideInputErrorLabel);
  input.addEventListener('change', hideInputErrorLabel);

  // Handle checkbox change and set initial state
  checkbox.addEventListener('change', updateInputDisabledState);
  updateInputDisabledState();
}

export default function initAccountAndLimitsSection() {
  initUserInternalRegexPlaceholder();
  initDeactivateDormantUsersPeriodInputSection();
}
