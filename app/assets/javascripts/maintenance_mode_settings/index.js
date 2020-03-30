import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import MaintenanceModeSettingsApp from './components/app.vue';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-maintenance-mode-settings');

  return new Vue({
    el,
    components: {
      MaintenanceModeSettingsApp,
    },

    render(createElement) {
      return createElement('maintenance-mode-settings-app');
    },
  });
};
