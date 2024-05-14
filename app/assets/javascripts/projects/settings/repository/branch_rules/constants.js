import { s__ } from '~/locale';

export const I18N = {
  queryError: s__(
    'ProtectedBranch|An error occurred while loading branch rules. Please try again.',
  ),
  emptyState: s__(
    'ProtectedBranch|After you configure a protected branch, merge request approval, or status check, it appears here.',
  ),
  addBranchRule: s__('BranchRules|Add branch rule'),
  branchRuleModalDescription: s__(
    'BranchRules|To create a branch rule, you first need to create a protected branch.',
  ),
  branchRuleModalContent: s__(
    'BranchRules|After a protected branch is created, it will show up in the list as a branch rule.',
  ),
  createProtectedBranch: s__('BranchRules|Create protected branch'),
  createBranchRule: s__('BranchRules|Create branch rule'),
  branchName: s__('BranchRules|Branch name or pattern'),
  allBranches: s__('BranchRules|All branches'),
  allProtectedBranches: s__('BranchRules|All protected branches'),
  createBranchRuleError: s__('BranchRules|Something went wrong while creating branch rule.'),
  createBranchRuleSuccess: s__('BranchRules|Branch rule created.'),
};

export const PROTECTED_BRANCHES_ANCHOR = '#js-protected-branches-settings';

export const BRANCH_PROTECTION_MODAL_ID = 'addBranchRuleModal';
