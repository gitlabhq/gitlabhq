import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import IssuesListApp from 'ee_else_ce/issues/list/components/issues_list_app.vue';
import { getApolloProvider } from '~/issues/list/issue_client';
import { parseBoolean } from '~/lib/utils/common_utils';
import DesignDetail from '~/work_items/components/design_management/design_preview/design_details.vue';
import { ROUTES } from '~/work_items/constants';
import JiraIssuesImportStatusApp from './components/jira_issues_import_status_app.vue';
import { gqlClient } from './graphql';

export async function mountJiraIssuesListApp() {
  const el = document.querySelector('.js-jira-issues-import-status-root');

  if (!el) {
    return null;
  }

  const { issuesPath, projectPath } = el.dataset;
  const canEdit = parseBoolean(el.dataset.canEdit);
  const isJiraConfigured = parseBoolean(el.dataset.isJiraConfigured);

  if (!isJiraConfigured || !canEdit) {
    return null;
  }

  Vue.use(VueApollo);

  return new Vue({
    el,
    name: 'JiraIssuesImportStatusRoot',
    apolloProvider: new VueApollo({
      defaultClient: await gqlClient(),
    }),
    render(createComponent) {
      return createComponent(JiraIssuesImportStatusApp, {
        props: {
          issuesPath,
          projectPath,
        },
      });
    },
  });
}

export async function mountIssuesListApp() {
  const el = document.querySelector('.js-issues-list-root');

  if (!el) {
    return null;
  }

  Vue.use(VueApollo);
  Vue.use(VueRouter);

  const {
    autocompleteAwardEmojisPath,
    calendarPath,
    canBulkUpdate,
    canCreateIssue,
    canCreateProjects,
    canEdit,
    canImportIssues,
    canReadCrmContact,
    canReadCrmOrganization,
    email,
    emailsHelpPagePath,
    exportCsvPath,
    fullPath,
    groupId,
    groupPath,
    hasAnyIssues,
    hasAnyProjects,
    hasBlockedIssuesFeature,
    hasCustomFieldsFeature,
    hasIssuableHealthStatusFeature,
    hasIssueDateFilterFeature,
    hasIssueWeightsFeature,
    hasIterationsFeature,
    hasOkrsFeature,
    hasQualityManagementFeature,
    hasScopedLabelsFeature,
    importCsvIssuesPath,
    initialEmail,
    initialSort,
    isIssueRepositioningDisabled,
    isProject,
    isPublicVisibilityRestricted,
    isSignedIn,
    markdownHelpPath,
    maxAttachmentSize,
    newIssuePath,
    newProjectPath,
    projectImportJiraPath,
    quickActionsHelpPath,
    releasesPath,
    resetPath,
    rssPath,
    projectNamespaceFullPath,
    showNewIssueLink,
    signInPath,
    wiCanAdminLabel,
    wiIssuesListPath,
    wiLabelsManagePath,
    wiReportAbusePath,
    wiNewCommentTemplatePaths,
    hasLinkedItemsEpicsFeature,
    timeTrackingLimitToHours,
    hasSubepicsFeature,
    hasStatusFeature,
  } = el.dataset;

  return new Vue({
    el,
    name: 'IssuesListRoot',
    apolloProvider: await getApolloProvider(),
    router: new VueRouter({
      base: window.location.pathname,
      mode: 'history',
      routes: [
        {
          name: 'root',
          path: '/',
        },
        {
          name: ROUTES.design,
          path: '/:iid/designs/:id',
          component: DesignDetail,
          beforeEnter({ params: { id } }, _, next) {
            if (typeof id === 'string') {
              next();
            }
          },
          props: ({ params: { id, iid } }) => ({ id, iid }),
        },
      ],
    }),
    provide: {
      autocompleteAwardEmojisPath,
      calendarPath,
      canBulkUpdate: parseBoolean(canBulkUpdate),
      canCreateIssue: parseBoolean(canCreateIssue),
      canCreateProjects: parseBoolean(canCreateProjects),
      canReadCrmContact: parseBoolean(canReadCrmContact),
      canReadCrmOrganization: parseBoolean(canReadCrmOrganization),
      fullPath,
      groupId,
      groupPath,
      hasAnyIssues: parseBoolean(hasAnyIssues),
      hasAnyProjects: parseBoolean(hasAnyProjects),
      hasBlockedIssuesFeature: parseBoolean(hasBlockedIssuesFeature),
      hasCustomFieldsFeature: parseBoolean(hasCustomFieldsFeature),
      hasIssuableHealthStatusFeature: parseBoolean(hasIssuableHealthStatusFeature),
      hasIssueDateFilterFeature: parseBoolean(hasIssueDateFilterFeature),
      hasIssueWeightsFeature: parseBoolean(hasIssueWeightsFeature),
      hasIterationsFeature: parseBoolean(hasIterationsFeature),
      hasOkrsFeature: parseBoolean(hasOkrsFeature),
      hasQualityManagementFeature: parseBoolean(hasQualityManagementFeature),
      hasScopedLabelsFeature: parseBoolean(hasScopedLabelsFeature),
      initialSort,
      isIssueRepositioningDisabled: parseBoolean(isIssueRepositioningDisabled),
      isGroup: !parseBoolean(isProject),
      isProject: parseBoolean(isProject),
      isPublicVisibilityRestricted: parseBoolean(isPublicVisibilityRestricted),
      isSignedIn: parseBoolean(isSignedIn),
      newIssuePath,
      newProjectPath,
      releasesPath,
      rssPath,
      projectNamespaceFullPath,
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
      // For work item modal
      canAdminLabel: wiCanAdminLabel,
      issuesListPath: wiIssuesListPath,
      labelsManagePath: wiLabelsManagePath,
      reportAbusePath: wiReportAbusePath,
      hasSubepicsFeature: parseBoolean(hasSubepicsFeature),
      hasLinkedItemsEpicsFeature: parseBoolean(hasLinkedItemsEpicsFeature),
      commentTemplatePaths: JSON.parse(wiNewCommentTemplatePaths),
      timeTrackingLimitToHours: parseBoolean(timeTrackingLimitToHours),
      hasStatusFeature: parseBoolean(hasStatusFeature),
    },
    render: (createComponent) => createComponent(IssuesListApp),
  });
}
