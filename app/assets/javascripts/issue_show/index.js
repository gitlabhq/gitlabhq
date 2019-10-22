import Vue from 'vue';
import issuableApp from './components/app.vue';
import { parseIssuableData } from './utils/parse_data';

export default function initIssueableApp() {
  return new Vue({
    el: document.getElementById('js-issuable-app'),
    components: {
      issuableApp,
    },
    render(createElement) {
      return createElement('issuable-app', {
        props: parseIssuableData(),
      });
    },
  });
}
