import Vue from 'vue';
import issuableApp from './components/app.vue';
import incidentTabs from './components/incident_tabs.vue';

export default function initIssuableApp(issuableData = {}) {
  return new Vue({
    el: document.getElementById('js-issuable-app'),
    components: {
      issuableApp,
    },
    render(createElement) {
      return createElement('issuable-app', {
        props: {
          ...issuableData,
          descriptionComponent: incidentTabs,
          showTitleBorder: false,
        },
      });
    },
  });
}
