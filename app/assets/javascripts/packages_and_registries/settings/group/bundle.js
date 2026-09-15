import Vue from 'vue';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';

import { parseBoolean } from '~/lib/utils/common_utils';
import Translate from '~/vue_shared/translate';
import SettingsApp from 'ee_else_ce/packages_and_registries/settings/group/components/group_settings_app.vue';
import { apolloProvider } from './graphql';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-packages-and-registries-settings');
  if (!el) {
    return null;
  }
  return initVueApp({
    el,
    name: 'PackagesSettingsAppRoot',
    apolloProvider,
    provide: {
      groupPath: el.dataset.groupPath,
      groupDependencyProxyPath: el.dataset.groupDependencyProxyPath,
      shouldRenderVirtualRegistriesSetting: parseBoolean(
        el.dataset.shouldRenderVirtualRegistriesSetting,
      ),
      virtualRegistryCleanupPolicyPath: el.dataset.virtualRegistryCleanupPolicyPath,
    },
    component: SettingsApp,
  });
};
