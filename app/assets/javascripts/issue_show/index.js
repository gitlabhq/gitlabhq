import Vue from 'vue';
import { initSidebarTracking } from 'ee_else_ce/event_tracking/issue_sidebar';
import issuableApp from './components/app.vue';
import { parseIssuableData } from './utils/parse_data';
import '../vue_shared/vue_resource_interceptor';

export default function initIssueableApp() {
  return new Vue({
    el: document.getElementById('js-issuable-app'),
    components: {
      issuableApp,
    },
    mounted() {
      initSidebarTracking();
    },
    render(createElement) {
      return createElement('issuable-app', {
        props: parseIssuableData(),
      });
    },
  });
}
