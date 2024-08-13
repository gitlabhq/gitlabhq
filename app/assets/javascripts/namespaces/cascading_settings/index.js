import Vue from 'vue';
import HamlLockTooltips from './components/haml_lock_tooltips.vue';

export const initCascadingSettingsLockTooltips = () => {
  const el = document.querySelector('.js-cascading-settings-lock-tooltips');

  if (!el) return false;

  return new Vue({
    el,
    render(createElement) {
      return createElement(HamlLockTooltips);
    },
  });
};
