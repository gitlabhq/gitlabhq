import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import View from 'ee_else_ce/projects/settings/branch_rules/components/view/index.vue';

export default function mountBranchRules(el, store) {
  if (!el) {
    return null;
  }

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const {
    projectPath,
    projectId,
    protectedBranchesPath,
    branchRulesPath,
    approvalRulesPath,
    statusChecksPath,
    branchesPath,
    showStatusChecks,
    showApprovers,
    showCodeOwners,
    showEnterpriseAccessLevels,
    canAdminProtectedBranches,
  } = el.dataset;

  return new Vue({
    el,
    store,
    apolloProvider,
    provide: {
      projectPath,
      projectId: parseInt(projectId, 10),
      branchRulesPath,
      protectedBranchesPath,
      approvalRulesPath,
      statusChecksPath,
      branchesPath,
      showStatusChecks: parseBoolean(showStatusChecks),
      showApprovers: parseBoolean(showApprovers),
      showCodeOwners: parseBoolean(showCodeOwners),
      showEnterpriseAccessLevels: parseBoolean(showEnterpriseAccessLevels),
      canAdminProtectedBranches: parseBoolean(canAdminProtectedBranches),
    },
    render(h) {
      return h(View);
    },
  });
}
