import { s__ } from '~/locale';

export const I18N = {
  manageProtectionsLinkTitle: s__('BranchRules|Manage in protected branches'),
  targetBranch: s__('BranchRules|Target branch'),
  branchNameOrPattern: s__('BranchRules|Branch name or pattern'),
  branch: s__('BranchRules|Target branch'),
  allBranches: s__('BranchRules|All branches'),
  matchingBranchesLinkTitle: s__('BranchRules|%{total} matching %{subject}'),
  protectBranchTitle: s__('BranchRules|Protect branch'),
  protectBranchDescription: s__(
    'BranchRules|Keep stable branches secure and force developers to use merge requests. %{linkStart}What are protected branches?%{linkEnd}',
  ),
  wildcardsHelpText: s__(
    'BranchRules|%{linkStart}Wildcards%{linkEnd} such as *-stable or production/ are supported',
  ),
  forcePushTitle: s__('BranchRules|Force push'),
  allowForcePushDescription: s__(
    'BranchRules|All users with push access are allowed to force push.',
  ),
  disallowForcePushDescription: s__('BranchRules|Force push is not allowed.'),
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
  allowedToPushHeader: s__('BranchRules|Allowed to push (%{total})'),
  allowedToMergeHeader: s__('BranchRules|Allowed to merge (%{total})'),
  approvalsHeader: s__('BranchRules|Required approvals (%{total})'),
  noData: s__('BranchRules|No data to display'),
};

export const BRANCH_PARAM_NAME = 'branch';

export const ALL_BRANCHES_WILDCARD = '*';

export const WILDCARDS_HELP_PATH =
  'user/project/protected_branches#configure-multiple-protected-branches-by-using-a-wildcard';

export const PROTECTED_BRANCHES_HELP_PATH = 'user/project/protected_branches';

export const APPROVALS_HELP_PATH = 'user/project/merge_requests/approvals/index.md';

export const STATUS_CHECKS_HELP_PATH = 'user/project/merge_requests/status_checks.md';
