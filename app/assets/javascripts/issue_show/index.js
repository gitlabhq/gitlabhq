import Vue from 'vue';
import sanitize from 'sanitize-html';
import issuableApp from './components/app.vue';
import '../vue_shared/vue_resource_interceptor';

export default function initIssueableApp() {
  const initialDataEl = document.getElementById('js-issuable-app-initial-data');
  const props = JSON.parse(sanitize(initialDataEl.textContent).replace(/&quot;/g, '"'));

  return new Vue({
    el: document.getElementById('js-issuable-app'),
    components: {
      issuableApp,
    },
    render(createElement) {
      return createElement('issuable-app', {
        props,
      });
    },
  });
}
