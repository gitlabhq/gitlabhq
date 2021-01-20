import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import SettingsApp from './components/group_settings_app.vue';
import { apolloProvider } from './graphql';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-packages-and-registries-settings');
  if (!el) {
    return null;
  }
  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(SettingsApp);
    },
  });
};
