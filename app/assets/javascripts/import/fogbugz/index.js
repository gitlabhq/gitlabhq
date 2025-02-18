import Vue from 'vue';
import App from './app.vue';

export function initFogbugzImportProjectForm() {
  const el = document.getElementById('js-vue-import-fogbugz-project-app');

  if (!el) {
    return null;
  }

  const { backButtonPath, formPath } = el.dataset;

  const props = { backButtonPath, formPath };

  return new Vue({
    el,
    render(createElement) {
      return createElement(App, { props });
    },
  });
}
