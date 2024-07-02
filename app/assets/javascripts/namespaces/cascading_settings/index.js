import Vue from 'vue';
import HamlLockPopovers from './components/haml_lock_popovers.vue';

export const initCascadingSettingsLockPopovers = () => {
  const el = document.querySelector('.js-cascading-settings-lock-popovers');

  if (!el) return false;

  return new Vue({
    el,
    render(createElement) {
      return createElement(HamlLockPopovers);
    },
  });
};
