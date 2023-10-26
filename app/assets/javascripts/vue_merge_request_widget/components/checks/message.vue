<script>
import { __ } from '~/locale';
import StatusIcon from '../widget/status_icon.vue';

const ICON_NAMES = {
  failed: 'failed',
  allowed_to_fail: 'neutral',
  passed: 'success',
};

const FAILURE_REASONS = {
  broken_status: __('Cannot merge the source into the target branch, due to a conflict.'),
  ci_must_pass: __('Pipeline must succeed.'),
  conflict: __('Merge conflicts must be resolved.'),
  discussions_not_resolved: __('Unresolved discussions must be resolved.'),
  draft_status: __('Merge request must not be draft.'),
  not_open: __('Merge request must be open.'),
  need_rebase: __('Merge request must be rebased, because a fast-forward merge is not possible.'),
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
      return ICON_NAMES[this.check.result];
    },
  },
  i18n: {
    FAILURE_REASONS,
  },
};
</script>

<template>
  <div class="gl-py-3 gl-pl-7">
    <div class="gl-display-flex">
      <status-icon :icon-name="iconName" :level="2" />
      <div class="gl-w-full gl-min-w-0">
        <div class="gl-display-flex">{{ $options.i18n.FAILURE_REASONS[check.identifier] }}</div>
      </div>
      <slot></slot>
    </div>
  </div>
</template>
