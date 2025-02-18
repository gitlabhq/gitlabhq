import Vue from 'vue';
import initBlob from '~/pages/projects/init_blob';
import redirectToCorrectPage from '~/blame/blame_redirect';
import BlamePreferences from '~/blame/preferences/blame_preferences.vue';
import { initFindFileShortcut } from '~/projects/behaviors';

const initBlamePreferences = () => {
  const el = document.getElementById('js-blame-preferences');
  if (!el) return false;

  return new Vue({
    el,
    render: (createElement) => createElement(BlamePreferences, { props: { hasRevsFile: true } }), // TODO: replace `hasRevsFile` with real data once API is ready
  });
};

redirectToCorrectPage();
initBlamePreferences();
initBlob();
initFindFileShortcut();
