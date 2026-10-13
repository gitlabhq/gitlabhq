import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import HamlLockPopovers from './components/haml_lock_popovers.vue';

export const initCascadingSettingsLockPopovers = () => {
  const el = document.querySelector('.js-cascading-settings-lock-popovers');

  if (!el) return false;

  return initVueApp({ el, name: 'HamlLockPopoversRoot', component: HamlLockPopovers });
};
