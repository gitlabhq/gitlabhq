import { initToggle } from '~/toggles';

/**
 * Uses a toggle element in combination with a hidden field
 * to force submit a form that updates the settings.
 *
 * Unlike other settings in this page, updating this setting uses
 * a full page refresh (submit). This is done to avoid adding
 * `allow_runner_registration_token` to any API as this setting
 * is discouraged.
 */
export const initAllowRunnerRegistrationTokenToggle = () => {
  const el = document.querySelector('.js-allow-runner-registration-token-toggle');
  const input = document.querySelector('.js-allow-runner-registration-token-input');

  if (el && input) {
    const toggle = initToggle(el);

    toggle.$on('change', (isEnabled) => {
      input.value = isEnabled;

      toggle.isLoading = true;

      toggle.$el.closest('form').requestSubmit();
    });
    return toggle;
  }

  return null;
};
