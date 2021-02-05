import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import issuableApp from './components/app.vue';
import incidentTabs from './components/incidents/incident_tabs.vue';

Vue.use(VueApollo);

export default function initIssuableApp(issuableData = {}) {
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const {
    canUpdate,
    iid,
    projectNamespace,
    projectPath,
    projectId,
    slaFeatureAvailable,
    uploadMetricsFeatureAvailable,
  } = issuableData;

  const fullPath = `${projectNamespace}/${projectPath}`;

  return new Vue({
    el: document.getElementById('js-issuable-app'),
    apolloProvider,
    components: {
      issuableApp,
    },
    provide: {
      canUpdate,
      fullPath,
      iid,
      projectId,
      slaFeatureAvailable: parseBoolean(slaFeatureAvailable),
      uploadMetricsFeatureAvailable: parseBoolean(uploadMetricsFeatureAvailable),
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
