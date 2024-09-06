import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import errorTrackingStore from '~/error_tracking/store';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import { TYPE_INCIDENT, TYPE_ISSUE } from '~/issues/constants';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import initLinkedResources from '~/linked_resources';
import IssueApp from './components/app.vue';
import DescriptionComponent from './components/description.vue';
import IncidentTabs from './components/incidents/incident_tabs.vue';
import SentryErrorStackTrace from './components/sentry_error_stack_trace.vue';
import { issueState } from './constants';
import getIssueStateQuery from './queries/get_issue_state.query.graphql';
import createRouter from './components/incidents/router';
import { parseIssuableData } from './utils/parse_data';

const bootstrapApollo = (state = {}) => {
  return apolloProvider.clients.defaultClient.cache.writeQuery({
    query: getIssueStateQuery,
    data: {
      issueState: state,
    },
  });
};

export function initIssuableApp(store) {
  const el = document.getElementById('js-issuable-app');

  if (!el) {
    return undefined;
  }

  const issuableData = parseIssuableData(el);
  const headerActionsData = convertObjectPropsToCamelCase(JSON.parse(el.dataset.headerActionsData));

  const {
    authorId,
    authorName,
    authorUsername,
    authorWebUrl,
    canCreateIncident,
    fullPath,
    iid,
    issuableId,
    issueType,
    hasIterationsFeature,
    imported,
    // for issue
    registerPath,
    signInPath,
    // for incident
    canUpdate,
    canUpdateTimelineEvent,
    currentPath,
    currentTab,
    hasLinkedAlerts,
    projectId,
    slaFeatureAvailable,
    uploadMetricsFeatureAvailable,
  } = issuableData;

  const issueProvideData = { registerPath, signInPath };
  const incidentProvideData = {
    canUpdate,
    canUpdateTimelineEvent,
    hasLinkedAlerts: parseBoolean(hasLinkedAlerts),
    projectId,
    slaFeatureAvailable: parseBoolean(slaFeatureAvailable),
    uploadMetricsFeatureAvailable: parseBoolean(uploadMetricsFeatureAvailable),
  };

  bootstrapApollo({ ...issueState, issueType });

  if (issueType === TYPE_INCIDENT) {
    initLinkedResources();
  }

  return new Vue({
    el,
    name: 'DescriptionRoot',
    apolloProvider,
    store,
    router: issueType === TYPE_INCIDENT ? createRouter(currentPath, currentTab) : undefined,
    provide: {
      canCreateIncident,
      fullPath,
      iid,
      issuableId,
      issueType,
      hasIterationsFeature,
      ...(issueType === TYPE_ISSUE && issueProvideData),
      ...(issueType === TYPE_INCIDENT && incidentProvideData),
      // for HeaderActions component
      canCreateIssue:
        issueType === TYPE_INCIDENT
          ? parseBoolean(headerActionsData.canCreateIncident)
          : parseBoolean(headerActionsData.canCreateIssue),
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
          ...issuableData,
          author: {
            id: authorId,
            name: authorName,
            username: authorUsername,
            webUrl: authorWebUrl,
          },
          descriptionComponent: issueType === TYPE_INCIDENT ? IncidentTabs : DescriptionComponent,
          isConfidential: this.getNoteableData?.confidential,
          isLocked: this.getNoteableData?.discussion_locked,
          isImported: imported,
          issuableStatus: this.getNoteableData?.state,
          issuableType: issueType,
          issueId: this.getNoteableData?.id?.toString(),
          issueIid: this.getNoteableData?.iid?.toString(),
          showTitleBorder: issueType !== TYPE_INCIDENT,
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
