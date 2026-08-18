import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import RapidDiffsToggle from '~/rapid_diffs/app/rapid_diffs_toggle.vue';

export function initRapidDiffsToggle() {
  const el = document.querySelector('#js-rapid-diffs-toggle .js-rapid-diffs-toggle-mount');
  if (!el) return null;
  if (!window.gon?.features?.rapidDiffsOnMrShow) return null;

  return initVueApp({ el, name: 'RapidDiffsToggleRoot', component: RapidDiffsToggle });
}
