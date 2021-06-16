import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import issuableApp from './components/app.vue';
import incidentTabs from './components/incidents/incident_tabs.vue';
import { issueState } from './constants';
import apolloProvider from './graphql';
import getIssueStateQuery from './queries/get_issue_state.query.graphql';

export default function initIssuableApp(issuableData = {}) {
  const el = document.getElementById('js-issuable-app');

  if (!el) {
    return undefined;
  }

  apolloProvider.clients.defaultClient.cache.writeQuery({
    query: getIssueStateQuery,
    data: {
      issueState: { ...issueState, issueType: el.dataset.issueType },
    },
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
    el,
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
