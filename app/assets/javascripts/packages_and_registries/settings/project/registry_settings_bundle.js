import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import Translate from '~/vue_shared/translate';
import RegistrySettingsApp from './components/registry_settings_app.vue';
import { apolloProvider } from './graphql/index';

Vue.use(GlToast);
Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-registry-settings');
  if (!el) {
    return null;
  }
  const {
    isAdmin,
    enableHistoricEntries,
    projectPath,
    adminSettingsPath,
    tagsRegexHelpPagePath,
    helpPagePath,
    showCleanupPolicyOnAlert,
  } = el.dataset;
  return new Vue({
    el,
    apolloProvider,
    components: {
      RegistrySettingsApp,
    },
    provide: {
      isAdmin: parseBoolean(isAdmin),
      enableHistoricEntries: parseBoolean(enableHistoricEntries),
      projectPath,
      adminSettingsPath,
      tagsRegexHelpPagePath,
      helpPagePath,
      showCleanupPolicyOnAlert: parseBoolean(showCleanupPolicyOnAlert),
    },
    render(createElement) {
      return createElement('registry-settings-app', {});
    },
  });
};
