import produce from 'immer';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import getIssuesQuery from 'ee_else_ce/issues/list/queries/get_issues.query.graphql';
import IssuesListApp from 'ee_else_ce/issues/list/components/issues_list_app.vue';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import JiraIssuesImportStatusRoot from './components/jira_issues_import_status_app.vue';

export function mountJiraIssuesListApp() {
  const el = document.querySelector('.js-jira-issues-import-status');

  if (!el) {
    return false;
  }

  const { issuesPath, projectPath } = el.dataset;
  const canEdit = parseBoolean(el.dataset.canEdit);
  const isJiraConfigured = parseBoolean(el.dataset.isJiraConfigured);

  if (!isJiraConfigured || !canEdit) {
    return false;
  }

  Vue.use(VueApollo);
  const defaultClient = createDefaultClient();
  const apolloProvider = new VueApollo({
    defaultClient,
  });

  return new Vue({
    el,
    name: 'JiraIssuesImportStatusRoot',
    apolloProvider,
    render(createComponent) {
      return createComponent(JiraIssuesImportStatusRoot, {
        props: {
          canEdit,
          isJiraConfigured,
          issuesPath,
          projectPath,
        },
      });
    },
  });
}

export function mountIssuesListApp() {
  const el = document.querySelector('.js-issues-list');

  if (!el) {
    return false;
  }

  Vue.use(VueApollo);
  Vue.use(VueRouter);

  const resolvers = {
    Mutation: {
      reorderIssues: (_, { oldIndex, newIndex, namespace, serializedVariables }, { cache }) => {
        const variables = JSON.parse(serializedVariables);
        const sourceData = cache.readQuery({ query: getIssuesQuery, variables });

        const data = produce(sourceData, (draftData) => {
          const issues = draftData[namespace].issues.nodes.slice();
          const issueToMove = issues[oldIndex];
          issues.splice(oldIndex, 1);
          issues.splice(newIndex, 0, issueToMove);

          draftData[namespace].issues.nodes = issues;
        });

        cache.writeQuery({ query: getIssuesQuery, variables, data });
      },
    },
  };

  const {
    autocompleteAwardEmojisPath,
    calendarPath,
    canBulkUpdate,
    canCreateProjects,
    canEdit,
    canImportIssues,
    canReadCrmContact,
    canReadCrmOrganization,
    email,
    emailsHelpPagePath,
    emptyStateSvgPath,
    exportCsvPath,
    fullPath,
    groupPath,
    hasAnyIssues,
    hasAnyProjects,
    hasBlockedIssuesFeature,
    hasIssuableHealthStatusFeature,
    hasIssueWeightsFeature,
    hasIterationsFeature,
    hasMultipleIssueAssigneesFeature,
    importCsvIssuesPath,
    initialEmail,
    initialSort,
    isAnonymousSearchDisabled,
    isIssueRepositioningDisabled,
    isProject,
    isPublicVisibilityRestricted,
    isSignedIn,
    jiraIntegrationPath,
    markdownHelpPath,
    maxAttachmentSize,
    newIssuePath,
    newProjectPath,
    projectImportJiraPath,
    quickActionsHelpPath,
    releasesPath,
    resetPath,
    rssPath,
    showNewIssueLink,
    signInPath,
  } = el.dataset;

  return new Vue({
    el,
    name: 'IssuesListRoot',
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(resolvers),
    }),
    router: new VueRouter({
      base: window.location.pathname,
      mode: 'history',
      routes: [{ path: '/' }],
    }),
    provide: {
      autocompleteAwardEmojisPath,
      calendarPath,
      canBulkUpdate: parseBoolean(canBulkUpdate),
      canCreateProjects: parseBoolean(canCreateProjects),
      canReadCrmContact: parseBoolean(canReadCrmContact),
      canReadCrmOrganization: parseBoolean(canReadCrmOrganization),
      emptyStateSvgPath,
      fullPath,
      groupPath,
      hasAnyIssues: parseBoolean(hasAnyIssues),
      hasAnyProjects: parseBoolean(hasAnyProjects),
      hasBlockedIssuesFeature: parseBoolean(hasBlockedIssuesFeature),
      hasIssuableHealthStatusFeature: parseBoolean(hasIssuableHealthStatusFeature),
      hasIssueWeightsFeature: parseBoolean(hasIssueWeightsFeature),
      hasIterationsFeature: parseBoolean(hasIterationsFeature),
      hasMultipleIssueAssigneesFeature: parseBoolean(hasMultipleIssueAssigneesFeature),
      initialSort,
      isAnonymousSearchDisabled: parseBoolean(isAnonymousSearchDisabled),
      isIssueRepositioningDisabled: parseBoolean(isIssueRepositioningDisabled),
      isProject: parseBoolean(isProject),
      isPublicVisibilityRestricted: parseBoolean(isPublicVisibilityRestricted),
      isSignedIn: parseBoolean(isSignedIn),
      jiraIntegrationPath,
      newIssuePath,
      newProjectPath,
      releasesPath,
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
      showExportButton: parseBoolean(hasAnyIssues),
      showImportButton: parseBoolean(canImportIssues),
      showLabel: !parseBoolean(hasAnyIssues),
      // For IssuableByEmail component
      emailsHelpPagePath,
      initialEmail,
      markdownHelpPath,
      quickActionsHelpPath,
      resetPath,
    },
    render: (createComponent) => createComponent(IssuesListApp),
  });
}
