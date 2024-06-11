<script>
import { GlIcon, GlPopover } from '@gitlab/ui';
import { CLUSTER_ERRORS } from '../constants';

export default {
  components: {
    GlIcon,
    GlPopover,
  },
  props: {
    errorType: {
      type: String,
      required: false,
      default: '',
    },
    popoverId: {
      type: String,
      required: true,
    },
  },
  computed: {
    errorContent() {
      return CLUSTER_ERRORS[this.errorType] || CLUSTER_ERRORS.default;
    },
  },
};
</script>

<template>
  <div :id="popoverId">
    <span class="gl-italic">
      {{ errorContent.tableText }}
    </span>

    <gl-icon name="status_warning" :size="24" class="gl-p-2" />

    <gl-popover :container="popoverId" :target="popoverId" placement="top">
      <template #title>
        <span class="gl-block gl-text-left">{{ errorContent.title }}</span>
      </template>

      <p class="gl-text-left">{{ errorContent.description }}</p>

      <p class="gl-text-left">{{ s__('ClusterIntegration|Troubleshooting tips:') }}</p>

      <ul class="gl-text-left">
        <li v-for="tip in errorContent.troubleshootingTips" :key="tip">
          {{ tip }}
        </li>
      </ul>
    </gl-popover>
  </div>
</template>
