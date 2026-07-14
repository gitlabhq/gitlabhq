import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import View from 'ee_else_ce/projects/settings/branch_rules/components/index.vue';

export default function mountBranchRules(el, store, squashOptionsFeatureAvailable = false) {
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
    securityPoliciesPath,
    showStatusChecks,
    showApprovers,
    showCodeOwners,
    showEnterpriseAccessLevels,
    customRolesForProtectedBranchesEnabled,
    canAdminProtectedBranches,
    canAdminGroupProtectedBranches,
    groupSettingsRepositoryPath,
    canReadSquashOption = 'false',
    canUpdateSquashOption = 'false',
  } = el.dataset;

  return new Vue({
    el,
    name: 'ViewRoot',
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
      securityPoliciesPath,
      showStatusChecks: parseBoolean(showStatusChecks),
      showApprovers: parseBoolean(showApprovers),
      showCodeOwners: parseBoolean(showCodeOwners),
      showEnterpriseAccessLevels: parseBoolean(showEnterpriseAccessLevels),
      customRolesForProtectedBranchesEnabled: parseBoolean(customRolesForProtectedBranchesEnabled),
      canAdminProtectedBranches: parseBoolean(canAdminProtectedBranches),
      canAdminGroupProtectedBranches: parseBoolean(canAdminGroupProtectedBranches),
      groupSettingsRepositoryPath,
      squashOptionsFeatureAvailable,
      canReadSquashOption: parseBoolean(canReadSquashOption),
      canUpdateSquashOption: parseBoolean(canUpdateSquashOption),
    },
    render(h) {
      return h(View);
    },
  });
}
