<script>
import StatusIcon from '../widget/status_icon.vue';
import { FAILURE_REASONS } from './constants';

const ICON_NAMES = {
  failed: 'failed',
  inactive: 'neutral',
  success: 'success',
  warning: 'warning',
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
  <div class="gl-py-3 gl-pl-7 gl-pr-4">
    <div class="gl-display-flex">
      <status-icon :icon-name="iconName" :level="2" />
      <div class="gl-w-full gl-min-w-0">
        <div class="gl-display-flex">{{ failureReason }}</div>
      </div>
      <slot></slot>
      <slot v-if="check.status === 'FAILED'" name="failed"></slot>
      <slot v-if="check.status === 'WARNING'" name="warning"></slot>
    </div>
  </div>
</template>
