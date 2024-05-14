import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import UpdateSharedRunnersForm from './components/shared_runners_form.vue';

export default (containerId = 'update-shared-runners-form') => {
  const containerEl = document.getElementById(containerId);

  if (!containerEl) return null;

  const {
    groupId,
    groupName,
    groupIsEmpty,
    sharedRunnersSetting,
    parentName,
    parentSettingsPath,
    parentSharedRunnersSetting,
    runnerEnabledValue,
    runnerDisabledValue,
    runnerAllowOverrideValue,
  } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    provide: {
      groupId,
      groupName,
      groupIsEmpty: parseBoolean(groupIsEmpty),
      sharedRunnersSetting,

      runnerEnabledValue,
      runnerDisabledValue,
      runnerAllowOverrideValue,

      parentName,
      parentSettingsPath,
      parentSharedRunnersSetting,
    },
    render(createElement) {
      return createElement(UpdateSharedRunnersForm);
    },
  });
};
