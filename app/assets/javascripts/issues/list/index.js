import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { parseBoolean } from '~/lib/utils/common_utils';
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
