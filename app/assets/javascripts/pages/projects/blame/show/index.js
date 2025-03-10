import Vue from 'vue';
import initBlob from '~/pages/projects/init_blob';
import redirectToCorrectPage from '~/blame/blame_redirect';
import BlamePreferences from '~/blame/preferences/blame_preferences.vue';
import { initFindFileShortcut } from '~/projects/behaviors';
import { parseBoolean } from '~/lib/utils/common_utils';

const initBlamePreferences = () => {
  const el = document.getElementById('js-blame-preferences');
  if (!el) return false;

  const { hasRevsFile } = el.dataset;

  return new Vue({
    el,
    render: (createElement) =>
      createElement(BlamePreferences, { props: { hasRevsFile: parseBoolean(hasRevsFile) } }),
  });
};

redirectToCorrectPage();
initBlamePreferences();
initBlob();
initFindFileShortcut();
