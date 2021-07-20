import Vue from 'vue';
import VueApollo from 'vue-apollo';
import JiraConnectNewBranchForm from '~/jira_connect/branches/components/new_branch_form.vue';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueApollo);

export default async function initJiraConnectBranches() {
  const el = document.querySelector('.js-jira-connect-create-branch');
  if (!el) {
    return null;
  }

  const { initialBranchName } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(
      {},
      {
        assumeImmutableResults: true,
      },
    ),
  });

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(JiraConnectNewBranchForm, {
        props: {
          initialBranchName,
        },
      });
    },
  });
}
