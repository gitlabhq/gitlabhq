import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import InstanceRunnersToggle from '~/projects/settings/components/instance_runners_toggle.vue';

export const initInstanceRunnersToggle = (containerId = 'instance-runners-toggle-container') => {
  const containerEl = document.getElementById(containerId);
  if (!containerEl) {
    return null;
  }

  const {
    // required
    isDisabledAndUnoverridable,
    isEnabled,
    updatePath,
    identityVerificationPath,

    // optional
    groupName,
    groupSettingsPath,
  } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    provide: {
      identityVerificationPath,

      // Normally this will have a value from a helper. We set it to true here
      // because the alert that uses the value is only rendered if a specific
      // error is returned from the backend after the update project settings
      // XHR request completes
      identityVerificationRequired: true,
    },
    render(createElement) {
      return createElement(InstanceRunnersToggle, {
        props: {
          isDisabledAndUnoverridable: parseBoolean(isDisabledAndUnoverridable),
          isEnabled: parseBoolean(isEnabled),
          updatePath,

          groupName,
          groupSettingsPath,
        },
      });
    },
  });
};
