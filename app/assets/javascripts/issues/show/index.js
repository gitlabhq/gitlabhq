import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import errorTrackingStore from '~/error_tracking/store';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import { TYPE_INCIDENT, TYPE_ISSUE } from '~/issues/constants';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import { scrollToTargetOnResize } from '~/lib/utils/resize_observer';
import IssueApp from './components/app.vue';
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

  bootstrapApollo({ ...issueState, issueType: TYPE_INCIDENT });

  const {
    authorId,
    authorName,
    authorUsername,
    authorWebUrl,
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
  } = issueData;
  const headerActionsData = convertObjectPropsToCamelCase(JSON.parse(el.dataset.headerActionsData));

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
      // for HeaderActions component
      canCreateIssue: parseBoolean(headerActionsData.canCreateIncident),
      canDestroyIssue: parseBoolean(headerActionsData.canDestroyIssue),
      canPromoteToEpic: parseBoolean(headerActionsData.canPromoteToEpic),
      canReopenIssue: parseBoolean(headerActionsData.canReopenIssue),
      canReportSpam: parseBoolean(headerActionsData.canReportSpam),
      canUpdateIssue: parseBoolean(headerActionsData.canUpdateIssue),
      isIssueAuthor: parseBoolean(headerActionsData.isIssueAuthor),
      issuePath: headerActionsData.issuePath,
      newIssuePath: headerActionsData.newIssuePath,
      projectPath: headerActionsData.projectPath,
      reportAbusePath: headerActionsData.reportAbusePath,
      reportedUserId: headerActionsData.reportedUserId,
      reportedFromUrl: headerActionsData.reportedFromUrl,
      submitAsSpamPath: headerActionsData.submitAsSpamPath,
      issuableEmailAddress: headerActionsData.issuableEmailAddress,
    },
    computed: {
      ...mapGetters(['getNoteableData']),
    },
    render(createElement) {
      return createElement(IssueApp, {
        props: {
          ...issueData,
          author: {
            id: authorId,
            name: authorName,
            username: authorUsername,
            webUrl: authorWebUrl,
          },
          issueId: Number(issuableId),
          issuableStatus: this.getNoteableData?.state,
          issuableType: TYPE_INCIDENT,
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
  const headerActionsData = convertObjectPropsToCamelCase(JSON.parse(el.dataset.headerActionsData));

  scrollToTargetOnResize();

  bootstrapApollo({ ...issueState, issueType: TYPE_ISSUE });

  const {
    authorId,
    authorName,
    authorUsername,
    authorWebUrl,
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
      // for HeaderActions component
      canCreateIssue: parseBoolean(headerActionsData.canCreateIssue),
      canDestroyIssue: parseBoolean(headerActionsData.canDestroyIssue),
      canPromoteToEpic: parseBoolean(headerActionsData.canPromoteToEpic),
      canReopenIssue: parseBoolean(headerActionsData.canReopenIssue),
      canReportSpam: parseBoolean(headerActionsData.canReportSpam),
      canUpdateIssue: parseBoolean(headerActionsData.canUpdateIssue),
      iid: headerActionsData.iid,
      issuableId: headerActionsData.issuableId,
      isIssueAuthor: parseBoolean(headerActionsData.isIssueAuthor),
      issuePath: headerActionsData.issuePath,
      issueType: headerActionsData.issueType,
      newIssuePath: headerActionsData.newIssuePath,
      projectPath: headerActionsData.projectPath,
      projectId: headerActionsData.projectId,
      reportAbusePath: headerActionsData.reportAbusePath,
      reportedUserId: headerActionsData.reportedUserId,
      reportedFromUrl: headerActionsData.reportedFromUrl,
      submitAsSpamPath: headerActionsData.submitAsSpamPath,
      issuableEmailAddress: headerActionsData.issuableEmailAddress,
    },
    computed: {
      ...mapGetters(['getNoteableData']),
    },
    render(createElement) {
      return createElement(IssueApp, {
        props: {
          ...issueProps,
          author: {
            id: authorId,
            name: authorName,
            username: authorUsername,
            webUrl: authorWebUrl,
          },
          isConfidential: this.getNoteableData?.confidential,
          isLocked: this.getNoteableData?.discussion_locked,
          issuableStatus: this.getNoteableData?.state,
          issueId: this.getNoteableData?.id,
          issueIid: this.getNoteableData?.iid,
        },
      });
    },
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
