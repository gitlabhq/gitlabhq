import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import store from './stores/';
import RegistrySettingsApp from './components/registry_settings_app.vue';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-registry-settings');
  if (!el) {
    return null;
  }
  store.dispatch('setInitialState', el.dataset);
  return new Vue({
    el,
    store,
    components: {
      RegistrySettingsApp,
    },
    render(createElement) {
      return createElement('registry-settings-app', {});
    },
  });
};
