import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import DiffsColors from './components/diffs_colors.vue';

export default () => {
  const el = document.querySelector('#js-profile-preferences-diffs-colors-app');

  if (!el) return false;

  const { deletion, addition } = el.dataset;

  return initVueApp({
    el,
    name: 'PreferencesDiffsColorsRoot',
    provide: {
      deletion,
      addition,
    },
    component: DiffsColors,
  });
};
