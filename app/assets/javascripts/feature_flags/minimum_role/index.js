import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { parseBoolean } from '~/lib/utils/common_utils';
import FeatureFlagsMinimumRole from '~/feature_flags/minimum_role/feature_flags_minimum_role.vue';

export default (containerId = 'js-feature-flags-minimum-role-app') => {
  const containerEl = document.getElementById(containerId);

  if (!containerEl) {
    return false;
  }

  const { projectFullPath, minimumRole, canUpdate } = containerEl.dataset;

  return initVueApp({
    el: containerEl,
    name: 'FeatureFlagsMinimumRoleRoot',
    provide: {
      projectFullPath,
      minimumRole,
      canUpdate: parseBoolean(canUpdate),
    },
    component: FeatureFlagsMinimumRole,
  });
};
