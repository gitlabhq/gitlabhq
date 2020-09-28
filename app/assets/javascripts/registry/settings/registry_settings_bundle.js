import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import Translate from '~/vue_shared/translate';
import store from './store';
import RegistrySettingsApp from './components/registry_settings_app.vue';
import { apolloProvider } from './graphql/index';

Vue.use(GlToast);
Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-registry-settings');
  if (!el) {
    return null;
  }
  store.dispatch('setInitialState', el.dataset);
  const { projectPath, isAdmin, adminSettingsPath, enableHistoricEntries } = el.dataset;
  return new Vue({
    el,
    store,
    apolloProvider,
    components: {
      RegistrySettingsApp,
    },
    provide: {
      projectPath,
      isAdmin,
      adminSettingsPath,
      enableHistoricEntries,
    },
    render(createElement) {
      return createElement('registry-settings-app', {});
    },
  });
};
