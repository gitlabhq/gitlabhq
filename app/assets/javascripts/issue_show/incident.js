import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import issuableApp from './components/app.vue';
import incidentTabs from './components/incidents/incident_tabs.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

Vue.use(VueApollo);

export default function initIssuableApp(issuableData = {}) {
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const { iid, projectNamespace, projectPath, slaFeatureAvailable } = issuableData;

  return new Vue({
    el: document.getElementById('js-issuable-app'),
    apolloProvider,
    components: {
      issuableApp,
    },
    provide: {
      fullPath: `${projectNamespace}/${projectPath}`,
      iid,
      slaFeatureAvailable: parseBoolean(slaFeatureAvailable),
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
