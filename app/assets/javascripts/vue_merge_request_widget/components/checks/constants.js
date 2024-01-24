import { __ } from '~/locale';

export const COMPONENTS = {
  conflict: () => import('./conflicts.vue'),
  discussions_not_resolved: () => import('./unresolved_discussions.vue'),
  draft_status: () => import('./draft.vue'),
  need_rebase: () => import('./rebase.vue'),
  default: () => import('./message.vue'),
};

export const FAILURE_REASONS = {
  broken_status: __('Cannot merge the source into the target branch, due to a conflict.'),
  ci_must_pass: __('Pipeline must succeed.'),
  conflict: __('Merge conflicts must be resolved.'),
  discussions_not_resolved: __('Unresolved discussions must be resolved.'),
  draft_status: __('Merge request must not be draft.'),
  not_open: __('Merge request must be open.'),
  need_rebase: __('Merge request must be rebased, because a fast-forward merge is not possible.'),
  not_approved: __('All required approvals must be given.'),
  policies_denied: __('Denied licenses must be removed or approved.'),
  merge_request_blocked: __('Merge request is blocked by another merge request.'),
  status_checks_must_pass: __('Status checks must pass.'),
  jira_association_missing: __('Either the title or description must reference a Jira issue.'),
};
