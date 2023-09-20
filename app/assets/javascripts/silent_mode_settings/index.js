import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import { parseBoolean } from '~/lib/utils/common_utils';
import SilentModeSettingsApp from './components/app.vue';

Vue.use(Translate);

export const initSilentModeSettings = () => {
  const el = document.getElementById('js-silent-mode-settings');

  if (!el) {
    return false;
  }

  const { silentModeEnabled } = el.dataset;

  return new Vue({
    el,
    render(createElement) {
      return createElement(SilentModeSettingsApp, {
        props: {
          isSilentModeEnabled: parseBoolean(silentModeEnabled),
        },
      });
    },
  });
};
