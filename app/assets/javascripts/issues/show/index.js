import Vue from 'vue';
import { mapGetters } from 'vuex';
import errorTrackingStore from '~/error_tracking/store';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import { TYPE_INCIDENT } from '~/issues/constants';
import { parseBoolean } from '~/lib/utils/common_utils';
import { scrollToTargetOnResize } from '~/lib/utils/resize_observer';
import IssueApp from './components/app.vue';
import HeaderActions from './components/header_actions.vue';
import IncidentTabs from './components/incidents/incident_tabs.vue';
import SentryErrorStackTrace from './components/sentry_error_stack_trace.vue';
import { issueState } from './constants';
import getIssueStateQuery from './queries/get_issue_state.query.graphql';
import createRouter from './components/incidents/router';

const bootstrapApollo = (state = {}) => {
  return apolloProvider.clients.defaultClient.cache.writeQuery({
    query: getIssueStateQuery,
    data: {
      issueState: state,
    },
  });
};

export function initIncidentApp(issueData = {}, store) {
  const el = document.getElementById('js-issuable-app');

  if (!el) {
    return undefined;
  }

  bootstrapApollo({ ...issueState, issueType: el.dataset.issueType });

  const {
    canCreateIncident,
    canUpdate,
    canUpdateTimelineEvent,
    iid,
    issuableId,
    currentPath,
    currentTab,
    projectNamespace,
    projectPath,
    projectId,
    hasLinkedAlerts,
    slaFeatureAvailable,
    uploadMetricsFeatureAvailable,
    state,
  } = issueData;

  const fullPath = `${projectNamespace}/${projectPath}`;
  const router = createRouter(currentPath, currentTab);

  return new Vue({
    el,
    name: 'DescriptionRoot',
    apolloProvider,
    store,
    router,
    provide: {
      issueType: TYPE_INCIDENT,
      canCreateIncident,
      canUpdateTimelineEvent,
      canUpdate,
      fullPath,
      iid,
      issuableId,
      projectId,
      hasLinkedAlerts: parseBoolean(hasLinkedAlerts),
      slaFeatureAvailable: parseBoolean(slaFeatureAvailable),
      uploadMetricsFeatureAvailable: parseBoolean(uploadMetricsFeatureAvailable),
      contentEditorOnIssues: gon.features.contentEditorOnIssues,
    },
    computed: {
      ...mapGetters(['getNoteableData']),
    },
    render(createElement) {
      return createElement(IssueApp, {
        props: {
          ...issueData,
          issueId: Number(issuableId),
          issuableStatus: state,
          descriptionComponent: IncidentTabs,
          showTitleBorder: false,
          isConfidential: this.getNoteableData?.confidential,
        },
      });
    },
  });
}

export function initIssueApp(issueData, store) {
  const el = document.getElementById('js-issuable-app');

  if (!el) {
    return undefined;
  }

  const { fullPath, registerPath, signInPath } = el.dataset;

  scrollToTargetOnResize();

  bootstrapApollo({ ...issueState, issueType: el.dataset.issueType });

  const {
    canCreateIncident,
    hasIssueWeightsFeature,
    hasIterationsFeature,
    ...issueProps
  } = issueData;

  return new Vue({
    el,
    name: 'DescriptionRoot',
    apolloProvider,
    store,
    provide: {
      canCreateIncident,
      fullPath,
      registerPath,
      signInPath,
      hasIssueWeightsFeature,
      hasIterationsFeature,
    },
    computed: {
      ...mapGetters(['getNoteableData']),
    },
    render(createElement) {
      return createElement(IssueApp, {
        props: {
          ...issueProps,
          isConfidential: this.getNoteableData?.confidential,
          isLocked: this.getNoteableData?.discussion_locked,
          issuableStatus: this.getNoteableData?.state,
          issueId: this.getNoteableData?.id,
        },
      });
    },
  });
}

export function initHeaderActions(store, type = '') {
  const el = document.querySelector('.js-issue-header-actions');

  if (!el) {
    return undefined;
  }

  bootstrapApollo({ ...issueState, issueType: el.dataset.issueType });

  const canCreate =
    type === TYPE_INCIDENT ? el.dataset.canCreateIncident : el.dataset.canCreateIssue;

  return new Vue({
    el,
    name: 'HeaderActionsRoot',
    apolloProvider,
    store,
    provide: {
      canCreateIssue: parseBoolean(canCreate),
      canDestroyIssue: parseBoolean(el.dataset.canDestroyIssue),
      canPromoteToEpic: parseBoolean(el.dataset.canPromoteToEpic),
      canReopenIssue: parseBoolean(el.dataset.canReopenIssue),
      canReportSpam: parseBoolean(el.dataset.canReportSpam),
      canUpdateIssue: parseBoolean(el.dataset.canUpdateIssue),
      iid: el.dataset.iid,
      isIssueAuthor: parseBoolean(el.dataset.isIssueAuthor),
      issuePath: el.dataset.issuePath,
      issueType: el.dataset.issueType,
      newIssuePath: el.dataset.newIssuePath,
      projectPath: el.dataset.projectPath,
      projectId: el.dataset.projectId,
      reportAbusePath: el.dataset.reportAbusePath,
      reportedUserId: parseInt(el.dataset.reportedUserId, 10),
      reportedFromUrl: el.dataset.reportedFromUrl,
      submitAsSpamPath: el.dataset.submitAsSpamPath,
    },
    render: (createElement) => createElement(HeaderActions),
  });
}

export function initSentryErrorStackTrace() {
  const el = document.querySelector('#js-sentry-error-stack-trace');

  if (!el) {
    return undefined;
  }

  const { issueStackTracePath } = el.dataset;

  return new Vue({
    el,
    name: 'SentryErrorStackTraceRoot',
    store: errorTrackingStore,
    render: (createElement) =>
      createElement(SentryErrorStackTrace, { props: { issueStackTracePath } }),
  });
}
