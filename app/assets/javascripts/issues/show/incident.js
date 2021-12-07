import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import issuableApp from './components/app.vue';
import incidentTabs from './components/incidents/incident_tabs.vue';
import { issueState, IncidentType } from './constants';
import apolloProvider from './graphql';
import getIssueStateQuery from './queries/get_issue_state.query.graphql';
import HeaderActions from './components/header_actions.vue';

const bootstrapApollo = (state = {}) => {
  return apolloProvider.clients.defaultClient.cache.writeQuery({
    query: getIssueStateQuery,
    data: {
      issueState: state,
    },
  });
};

export function initIncidentApp(issuableData = {}) {
  const el = document.getElementById('js-issuable-app');

  if (!el) {
    return undefined;
  }

  bootstrapApollo({ ...issueState, issueType: el.dataset.issueType });

  const {
    canCreateIncident,
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
      issueType: IncidentType,
      canCreateIncident,
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

export function initIncidentHeaderActions(store) {
  const el = document.querySelector('.js-issue-header-actions');

  if (!el) {
    return undefined;
  }

  bootstrapApollo({ ...issueState, issueType: el.dataset.issueType });

  return new Vue({
    el,
    apolloProvider,
    store,
    provide: {
      canCreateIssue: parseBoolean(el.dataset.canCreateIncident),
      canPromoteToEpic: parseBoolean(el.dataset.canPromoteToEpic),
      canReopenIssue: parseBoolean(el.dataset.canReopenIssue),
      canReportSpam: parseBoolean(el.dataset.canReportSpam),
      canUpdateIssue: parseBoolean(el.dataset.canUpdateIssue),
      iid: el.dataset.iid,
      isIssueAuthor: parseBoolean(el.dataset.isIssueAuthor),
      issueType: el.dataset.issueType,
      newIssuePath: el.dataset.newIssuePath,
      projectPath: el.dataset.projectPath,
      projectId: el.dataset.projectId,
      reportAbusePath: el.dataset.reportAbusePath,
      submitAsSpamPath: el.dataset.submitAsSpamPath,
    },
    render: (createElement) => createElement(HeaderActions),
  });
}
