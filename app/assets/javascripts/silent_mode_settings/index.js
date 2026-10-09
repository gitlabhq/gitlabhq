import Vue from 'vue';
import { parseBoolean } from '@gitlab/frontend-utils';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import Translate from '~/vue_shared/translate';
import SilentModeSettingsApp from './components/app.vue';

Vue.use(Translate);

export const initSilentModeSettings = () => {
  const el = document.getElementById('js-silent-mode-settings');

  if (!el) {
    return false;
  }

  const { silentModeEnabled } = el.dataset;

  return initVueApp({
    el,
    name: 'SilentModeSettingsAppRoot',
    component: SilentModeSettingsApp,
    props: {
      isSilentModeEnabled: parseBoolean(silentModeEnabled),
    },
  });
};
