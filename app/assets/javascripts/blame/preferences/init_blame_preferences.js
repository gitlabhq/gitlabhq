import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { parseBoolean } from '~/lib/utils/common_utils';
import BlamePreferences from './blame_preferences.vue';

export const initBlamePreferences = () => {
  const el = document.getElementById('js-blame-preferences');

  if (!el) {
    return null;
  }

  const { hasRevsFile } = el.dataset;

  return initVueApp({
    el,
    name: 'BlamePreferencesRoot',
    component: BlamePreferences,
    props: { hasRevsFile: parseBoolean(hasRevsFile), showAgeIndicatorToggle: false },
  });
};
