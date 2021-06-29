import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { IssuableType } from '~/issue_show/constants';
import IssuesListApp from '~/issues_list/components/issues_list_app.vue';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import IssuablesListApp from './components/issuables_list_app.vue';
import JiraIssuesImportStatusRoot from './components/jira_issues_import_status_app.vue';

export function mountJiraIssuesListApp() {
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

export function mountIssuablesListApp() {
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

export function mountIssuesListApp() {
  const el = document.querySelector('.js-issues-list');

  if (!el) {
    return false;
  }

  Vue.use(VueApollo);

  const defaultClient = createDefaultClient({}, { assumeImmutableResults: true });
  const apolloProvider = new VueApollo({
    defaultClient,
  });

  const {
    autocompleteAwardEmojisPath,
    calendarPath,
    canBulkUpdate,
    canEdit,
    canImportIssues,
    email,
    emailsHelpPagePath,
    emptyStateSvgPath,
    exportCsvPath,
    groupEpicsPath,
    hasBlockedIssuesFeature,
    hasIssuableHealthStatusFeature,
    hasIssueWeightsFeature,
    hasIterationsFeature,
    hasMultipleIssueAssigneesFeature,
    hasProjectIssues,
    importCsvIssuesPath,
    initialEmail,
    isSignedIn,
    issuesPath,
    jiraIntegrationPath,
    markdownHelpPath,
    maxAttachmentSize,
    newIssuePath,
    projectImportJiraPath,
    projectPath,
    quickActionsHelpPath,
    resetPath,
    rssPath,
    showNewIssueLink,
    signInPath,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      autocompleteAwardEmojisPath,
      calendarPath,
      canBulkUpdate: parseBoolean(canBulkUpdate),
      emptyStateSvgPath,
      groupEpicsPath,
      hasBlockedIssuesFeature: parseBoolean(hasBlockedIssuesFeature),
      hasIssuableHealthStatusFeature: parseBoolean(hasIssuableHealthStatusFeature),
      hasIssueWeightsFeature: parseBoolean(hasIssueWeightsFeature),
      hasIterationsFeature: parseBoolean(hasIterationsFeature),
      hasMultipleIssueAssigneesFeature: parseBoolean(hasMultipleIssueAssigneesFeature),
      hasProjectIssues: parseBoolean(hasProjectIssues),
      isSignedIn: parseBoolean(isSignedIn),
      issuesPath,
      jiraIntegrationPath,
      newIssuePath,
      projectPath,
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
      showExportButton: parseBoolean(hasProjectIssues),
      showImportButton: parseBoolean(canImportIssues),
      showLabel: !parseBoolean(hasProjectIssues),
      // For IssuableByEmail component
      emailsHelpPagePath,
      initialEmail,
      issuableType: IssuableType.Issue,
      markdownHelpPath,
      quickActionsHelpPath,
      resetPath,
    },
    render: (createComponent) => createComponent(IssuesListApp),
  });
}
