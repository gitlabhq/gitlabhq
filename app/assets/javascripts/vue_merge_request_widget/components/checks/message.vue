<script>
import { GlLoadingIcon } from '@gitlab/ui';
import StatusIcon from '../widget/status_icon.vue';
import { FAILURE_REASONS, ICON_NAMES } from './constants';

export default {
  name: 'MergeChecksMessage',
  components: {
    GlLoadingIcon,
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
    <div class="gl-flex">
      <gl-loading-icon
        v-if="check.status === 'CHECKING'"
        size="sm"
        inline
        class="mr-widget-check-checking gl-mr-3 gl-self-center"
        data-testid="checking-icon"
      />
      <status-icon v-else :icon-name="iconName" :level="2" />
      <div class="gl-w-full gl-min-w-0">
        <div class="gl-flex">{{ failureReason }}</div>
      </div>
      <slot></slot>
      <slot v-if="check.status === 'FAILED'" name="failed"></slot>
      <slot v-if="check.status === 'WARNING'" name="warning"></slot>
    </div>
  </div>
</template>
