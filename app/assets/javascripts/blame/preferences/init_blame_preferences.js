import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import BlamePreferences from './blame_preferences.vue';

export const initBlamePreferences = () => {
  const el = document.getElementById('js-blame-preferences');

  if (!el) {
    return null;
  }

  const { hasRevsFile } = el.dataset;

  return new Vue({
    el,
    name: 'BlamePreferencesRoot',
    render: (createElement) =>
      createElement(BlamePreferences, {
        props: { hasRevsFile: parseBoolean(hasRevsFile), showAgeIndicatorToggle: false },
      }),
  });
};
