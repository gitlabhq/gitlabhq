import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import HamlLockTooltips from './components/haml_lock_tooltips.vue';

export const initCascadingSettingsLockTooltips = () => {
  const el = document.querySelector('.js-cascading-settings-lock-tooltips');

  if (!el) return false;

  return initVueApp({ el, name: 'HamlLockTooltipsRoot', component: HamlLockTooltips });
};
