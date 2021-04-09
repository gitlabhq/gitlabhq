import Vue from 'vue';
import VueApollo from 'vue-apollo';
import IssuesListApp from '~/issues_list/components/issues_list_app.vue';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import IssuablesListApp from './components/issuables_list_app.vue';
import JiraIssuesImportStatusRoot from './components/jira_issues_import_status_app.vue';

function mountJiraIssuesListApp() {
  const el = document.querySelector('.js-jira-issues-import-status');

  if (!el) {
    return false;
  }

  Vue.use(VueApollo);

  const defaultClient = createDefaultClient();
  const apolloProvider = new VueApollo({
    defaultClient,
  });

  return new Vue({
    el,
    apolloProvider,
    render(createComponent) {
      return createComponent(JiraIssuesImportStatusRoot, {
        props: {
          canEdit: parseBoolean(el.dataset.canEdit),
          isJiraConfigured: parseBoolean(el.dataset.isJiraConfigured),
          issuesPath: el.dataset.issuesPath,
          projectPath: el.dataset.projectPath,
        },
      });
    },
  });
}

function mountIssuablesListApp() {
  if (!gon.features?.vueIssuablesList) {
    return;
  }

  document.querySelectorAll('.js-issuables-list').forEach((el) => {
    const { canBulkEdit, emptyStateMeta = {}, scopedLabelsAvailable, ...data } = el.dataset;

    return new Vue({
      el,
      provide: {
        scopedLabelsAvailable: parseBoolean(scopedLabelsAvailable),
      },
      render(createElement) {
        return createElement(IssuablesListApp, {
          props: {
            ...data,
            emptyStateMeta:
              Object.keys(emptyStateMeta).length !== 0
                ? convertObjectPropsToCamelCase(JSON.parse(emptyStateMeta))
                : {},
            canBulkEdit: Boolean(canBulkEdit),
          },
        });
      },
    });
  });
}

export function initIssuesListApp() {
  const el = document.querySelector('.js-issues-list');

  if (!el) {
    return false;
  }

  const {
    calendarPath,
    canBulkUpdate,
    canEdit,
    canImportIssues,
    email,
    emptyStateSvgPath,
    endpoint,
    exportCsvPath,
    fullPath,
    hasBlockedIssuesFeature,
    hasIssuableHealthStatusFeature,
    hasIssues,
    hasIssueWeightsFeature,
    importCsvIssuesPath,
    isSignedIn,
    issuesPath,
    jiraIntegrationPath,
    maxAttachmentSize,
    newIssuePath,
    projectImportJiraPath,
    rssPath,
    showNewIssueLink,
    signInPath,
  } = el.dataset;

  return new Vue({
    el,
    // Currently does not use Vue Apollo, but need to provide {} for now until the
    // issue is fixed upstream in https://github.com/vuejs/vue-apollo/pull/1153
    apolloProvider: {},
    provide: {
      calendarPath,
      canBulkUpdate: parseBoolean(canBulkUpdate),
      emptyStateSvgPath,
      endpoint,
      fullPath,
      hasBlockedIssuesFeature: parseBoolean(hasBlockedIssuesFeature),
      hasIssuableHealthStatusFeature: parseBoolean(hasIssuableHealthStatusFeature),
      hasIssues: parseBoolean(hasIssues),
      hasIssueWeightsFeature: parseBoolean(hasIssueWeightsFeature),
      isSignedIn: parseBoolean(isSignedIn),
      issuesPath,
      jiraIntegrationPath,
      newIssuePath,
      rssPath,
      showNewIssueLink: parseBoolean(showNewIssueLink),
      signInPath,
      // For CsvImportExportButtons component
      canEdit: parseBoolean(canEdit),
      email,
      exportCsvPath,
      importCsvIssuesPath,
      maxAttachmentSize,
      projectImportJiraPath,
      showExportButton: parseBoolean(hasIssues),
      showImportButton: parseBoolean(canImportIssues),
      showLabel: !parseBoolean(hasIssues),
    },
    render: (createComponent) => createComponent(IssuesListApp),
  });
}

export default function initIssuablesList() {
  mountJiraIssuesListApp();
  mountIssuablesListApp();
}
