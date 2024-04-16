import { s__ } from '~/locale';

export const I18N = {
  pageTitle: s__('BranchRules|Branch rules details'),
  deleteRule: s__('BranchRules|Delete rule'),
  manageProtectionsLinkTitle: s__('BranchRules|Manage in protected branches'),
  targetBranch: s__('BranchRules|Target branch'),
  ruleTarget: s__('BranchRules|Rule target'),
  branchNameOrPattern: s__('BranchRules|Branch name or pattern'),
  allBranches: s__('BranchRules|All branches'),
  matchingBranchesLinkTitle: s__('BranchRules|%{total} matching %{subject}'),
  protectBranchTitle: s__('BranchRules|Protect branch'),
  protectBranchDescription: s__(
    'BranchRules|Keep stable branches secure and force developers to use merge requests. %{linkStart}What are protected branches?%{linkEnd}',
  ),
  approvalsTitle: s__('BranchRules|Approvals'),
  manageApprovalsLinkTitle: s__('BranchRules|Manage in merge request approvals'),
  approvalsDescription: s__(
    'BranchRules|Approvals to ensure separation of duties for new merge requests. %{linkStart}Learn more.%{linkEnd}',
  ),
  statusChecksTitle: s__('BranchRules|Status checks'),
  statusChecksDescription: s__(
    'BranchRules|Check for a status response in merge requests. Failures do not block merges. %{linkStart}Learn more.%{linkEnd}',
  ),
  statusChecksLinkTitle: s__('BranchRules|Manage in status checks'),
  statusChecksHeader: s__('BranchRules|Status checks (%{total})'),
  allowedToPushHeader: s__('BranchRules|Allowed to push and merge (%{total})'),
  allowedToMergeHeader: s__('BranchRules|Allowed to merge (%{total})'),
  allowForcePushTitle: s__('BranchRules|Allows force push'),
  doesNotAllowForcePushTitle: s__('BranchRules|Does not allow force push'),
  forcePushDescription: s__('BranchRules|From users with push access.'),
  requiresCodeOwnerApprovalTitle: s__('BranchRules|Requires approval from code owners'),
  doesNotRequireCodeOwnerApprovalTitle: s__(
    'BranchRules|Does not require approval from code owners',
  ),
  requiresCodeOwnerApprovalDescription: s__(
    'BranchRules|Also rejects code pushes that change files listed in CODEOWNERS file.',
  ),
  doesNotRequireCodeOwnerApprovalDescription: s__(
    'BranchRules|Also accepts code pushes that change files listed in CODEOWNERS file.',
  ),
  noData: s__('BranchRules|No data to display'),
  deleteRuleModalTitle: s__('BranchRules|Delete branch rule?'),
  deleteRuleModalText: s__(
    'BranchRules|Are you sure you want to delete this branch rule? This action cannot be undone.',
  ),
  deleteRuleModalDeleteText: s__('BranchRules|Delete branch rule'),
  updateTargetRule: s__('BranchRules|Update target branch'),
  update: s__('BranchRules|Update'),
  edit: s__('BranchRules|Edit'),
  updateBranchRuleError: s__('BranchRules|Something went wrong while updating branch rule.'),
};

export const EDIT_RULE_MODAL_ID = 'editRuleModal';

export const BRANCH_PARAM_NAME = 'branch';

export const ALL_BRANCHES_WILDCARD = '*';

export const PROTECTED_BRANCHES_HELP_PATH = 'user/project/protected_branches';

export const APPROVALS_HELP_PATH = 'user/project/merge_requests/approvals/index.md';

export const STATUS_CHECKS_HELP_PATH = 'user/project/merge_requests/status_checks.md';

export const REQUIRED_ICON = 'check-circle-filled';
export const NOT_REQUIRED_ICON = 'status-failed';

export const REQUIRED_ICON_CLASS = 'gl-fill-green-500';
export const NOT_REQUIRED_ICON_CLASS = 'gl-text-red-500';

export const DELETE_RULE_MODAL_ID = 'delete-branch-rule-modal';
