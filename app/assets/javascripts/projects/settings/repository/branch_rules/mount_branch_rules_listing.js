import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import BranchRulesApp from '~/projects/settings/repository/branch_rules/app.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default function mountBranchRulesListing(el) {
  if (!el) return null;

  const {
    projectPath,
    branchRulesPath,
    showCodeOwners,
    showStatusChecks,
    showApprovers,
    canAdminGroupProtectedBranches,
    groupSettingsRepositoryPath,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      projectPath,
      branchRulesPath,
      showCodeOwners: parseBoolean(showCodeOwners),
      showStatusChecks: parseBoolean(showStatusChecks),
      showApprovers: parseBoolean(showApprovers),
      canAdminGroupProtectedBranches: parseBoolean(canAdminGroupProtectedBranches),
      groupSettingsRepositoryPath,
    },
    render(createElement) {
      return createElement(BranchRulesApp);
    },
  });
}
