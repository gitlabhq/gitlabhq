import { __ } from '~/locale';

export const COMPONENTS = {
  conflict: () => import('./conflicts.vue'),
  discussions_not_resolved: () => import('./unresolved_discussions.vue'),
  draft_status: () => import('./draft.vue'),
  merge_time: () => import('./merge_time.vue'),
  need_rebase: () => import('./rebase.vue'),
  default: () => import('./message.vue'),
  requested_changes: () =>
    import('ee_component/vue_merge_request_widget/components/checks/requested_changes.vue'),
  locked_paths: () =>
    import('ee_component/vue_merge_request_widget/components/checks/locked_paths.vue'),
  locked_lfs_files: () =>
    import('ee_component/vue_merge_request_widget/components/checks/locked_paths.vue'),
  not_approved: () =>
    import('ee_component/vue_merge_request_widget/components/checks/not_approved.vue'),
  security_policy_violations: () =>
    import(
      'ee_component/vue_merge_request_widget/components/checks/security_policy_violations.vue'
    ),
};

export const FAILURE_REASONS = {
  commits_status: __('Source branch exists and contains commits.'),
  ci_must_pass: __('Pipeline must succeed.'),
  conflict: __('Merge conflicts must be resolved.'),
  discussions_not_resolved: __('Unresolved discussions must be resolved.'),
  draft_status: __('Merge request must not be draft.'),
  not_open: __('Merge request must be open.'),
  need_rebase: __('Merge request must be rebased, because a fast-forward merge is not possible.'),
  not_approved: __('All required approvals must be given.'),
  merge_request_blocked: __('Merge request dependencies must be merged.'),
  status_checks_must_pass: __('Status checks must pass.'),
  jira_association_missing: __('Either the title or description must reference a Jira issue.'),
  requested_changes: __('The change requests must be completed or resolved.'),
  approvals_syncing: __('The merge request approvals are currently syncing.'),
  locked_paths: __('All paths must be unlocked'),
  locked_lfs_files: __('All LFS files must be unlocked.'),
  security_policy_violations: __('All policy rules must be satisfied.'),
  merge_time: __('Cannot merge until this date and time.'),
};

export const ICON_NAMES = Object.freeze({
  failed: 'failed',
  inactive: 'neutral',
  success: 'success',
  warning: 'warning',
});
