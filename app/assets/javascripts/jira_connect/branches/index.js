import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import JiraConnectNewBranchPage from '~/jira_connect/branches/pages/index.vue';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueApollo);

export default function initJiraConnectBranches() {
  const el = document.querySelector('.js-jira-connect-create-branch');
  if (!el) {
    return null;
  }

  const { initialBranchName, successStateSvgPath } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return initVueApp({
    el,
    name: 'JiraConnectNewBranchRoot',
    apolloProvider,
    provide: {
      initialBranchName,
      successStateSvgPath,
    },
    component: JiraConnectNewBranchPage,
  });
}
