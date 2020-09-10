import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import issuableApp from './components/app.vue';
import incidentTabs from './components/incidents/incident_tabs.vue';

Vue.use(VueApollo);

export default function initIssuableApp(issuableData = {}) {
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const { projectNamespace, projectPath, iid } = issuableData;

  return new Vue({
    el: document.getElementById('js-issuable-app'),
    apolloProvider,
    components: {
      issuableApp,
    },
    provide: {
      fullPath: `${projectNamespace}/${projectPath}`,
      iid,
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
