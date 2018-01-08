<script>
import icon from '~/vue_shared/components/icon.vue';
import { HEALTH_STATUS_ICON } from '../constants';

export default {
  props: {
    status: {
      type: String,
      required: true,
    },
  },
  components: {
    icon,
  },
  computed: {
    healthCssClass() {
      return `geo-node-${this.status.toLowerCase()}`;
    },
    statusIconName() {
      return HEALTH_STATUS_ICON[this.status.toLowerCase()];
    },
  },
};
</script>

<template>
  <div
    class="node-detail-value node-health-status"
    :class="healthCssClass"
  >
    <icon
      :size="16"
      :name="statusIconName"
    />
    <span
      class="status-text prepend-left-5"
    >
      {{status}}
    </span>
  </div>
</template>
