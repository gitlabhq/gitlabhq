// This allows us to dismiss alerts and banners that we've migrated from bootstrap
// Note: This ONLY works on elements that are created on page load
// You can follow this effort in the following epic
// https://gitlab.com/groups/gitlab-org/-/epics/4070
import { __ } from '~/locale';

export default function initAlertHandler() {
  const DISMISSIBLE_SELECTORS = ['.gl-alert', '.gl-banner'];
  const DISMISS_LABEL = `[aria-label="${__('Dismiss')}"]`;
  const DISMISS_CLASS = '.gl-alert-dismiss';

  DISMISSIBLE_SELECTORS.forEach((selector) => {
    const elements = document.querySelectorAll(selector);
    elements.forEach((element) => {
      const button = element.querySelector(DISMISS_LABEL) || element.querySelector(DISMISS_CLASS);
      if (!button) {
        return;
      }
      button.addEventListener('click', () => element.remove());
    });
  });
}
