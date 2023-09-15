import Vue from 'vue';
import VueApollo from 'vue-apollo';
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

  return new Vue({
    el,
    name: 'JiraConnectNewBranchRoot',
    apolloProvider,
    provide: {
      initialBranchName,
      successStateSvgPath,
    },
    render(createElement) {
      return createElement(JiraConnectNewBranchPage);
    },
  });
}
