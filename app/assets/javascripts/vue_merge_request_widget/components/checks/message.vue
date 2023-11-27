<script>
import { __ } from '~/locale';
import StatusIcon from '../widget/status_icon.vue';

const ICON_NAMES = {
  failed: 'failed',
  inactive: 'neutral',
  success: 'success',
};

const FAILURE_REASONS = {
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

export default {
  name: 'MergeChecksMessage',
  components: {
    StatusIcon,
  },
  props: {
    check: {
      type: Object,
      required: true,
    },
    mr: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    iconName() {
      return ICON_NAMES[this.check.status.toLowerCase()];
    },
    failureReason() {
      return FAILURE_REASONS[this.check.identifier.toLowerCase()];
    },
  },
};
</script>

<template>
  <div class="gl-py-3 gl-pl-7">
    <div class="gl-display-flex">
      <status-icon :icon-name="iconName" :level="2" />
      <div class="gl-w-full gl-min-w-0">
        <div class="gl-display-flex">{{ failureReason }}</div>
      </div>
      <slot></slot>
      <slot v-if="check.status === 'FAILED'" name="failed"></slot>
    </div>
  </div>
</template>
