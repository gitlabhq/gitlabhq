<script>
import StatusIcon from '../widget/status_icon.vue';

const ICON_NAMES = {
  failed: 'failed',
  allowed_to_fail: 'neutral',
  passed: 'success',
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
};
</script>

<template>
  <div class="gl-py-3 gl-pl-7">
    <div class="gl-display-flex">
      <status-icon :icon-name="iconName" :level="2" />
      <div class="gl-w-full gl-min-w-0">
        <div class="gl-display-flex">{{ check.failureReason }}</div>
      </div>
      <slot></slot>
    </div>
  </div>
</template>
