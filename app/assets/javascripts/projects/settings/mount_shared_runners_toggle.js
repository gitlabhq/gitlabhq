import Vue from 'vue';
import SharedRunnersToggle from '~/projects/settings/components/shared_runners_toggle.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

export default (containerId = 'toggle-shared-runners-form') => {
  const containerEl = document.getElementById(containerId);
  const { isDisabledAndUnoverridable, isEnabled, updatePath } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    render(createElement) {
      return createElement(SharedRunnersToggle, {
        props: {
          isDisabledAndUnoverridable: parseBoolean(isDisabledAndUnoverridable),
          isEnabled: parseBoolean(isEnabled),
          updatePath,
        },
      });
    },
  });
};
