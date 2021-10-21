import Vue from 'vue';
import UpdateSharedRunnersForm from './components/shared_runners_form.vue';

export default (containerId = 'update-shared-runners-form') => {
  const containerEl = document.getElementById(containerId);

  const {
    updatePath,
    sharedRunnersAvailability,
    parentSharedRunnersAvailability,
    runnerEnabled,
    runnerDisabled,
    runnerAllowOverride,
  } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    render(createElement) {
      return createElement(UpdateSharedRunnersForm, {
        provide: {
          updatePath,
          sharedRunnersAvailability,
          parentSharedRunnersAvailability,
          runnerEnabled,
          runnerDisabled,
          runnerAllowOverride,
        },
      });
    },
  });
};
