import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import JiraIssuesListRoot from './components/jira_issues_list_root.vue';
import IssuablesListApp from './components/issuables_list_app.vue';

function mountJiraIssuesListApp() {
  const el = document.querySelector('.js-projects-issues-root');

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
      return createComponent(JiraIssuesListRoot, {
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
  if (!gon.features?.vueIssuablesList && !gon.features?.jiraIssuesIntegration) {
    return;
  }

  document.querySelectorAll('.js-issuables-list').forEach(el => {
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

export default function initIssuablesList() {
  mountJiraIssuesListApp();
  mountIssuablesListApp();
}
