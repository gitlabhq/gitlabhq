<script>
import { GlIcon } from '@gitlab/ui';
import { STATUS_FAILED, STATUS_NEUTRAL, STATUS_SUCCESS } from '../constants';

export default {
  name: 'IssueStatusIcon',
  components: {
    GlIcon,
  },
  props: {
    status: {
      type: String,
      required: true,
    },
    statusIconSize: {
      type: Number,
      required: false,
      default: 24,
    },
  },
  computed: {
    iconName() {
      if (this.isStatusFailed) {
        return 'status_failed_borderless';
      }
      if (this.isStatusSuccess) {
        return 'status_success_borderless';
      }

      return 'dash';
    },
    isStatusFailed() {
      return this.status === STATUS_FAILED;
    },
    isStatusSuccess() {
      return this.status === STATUS_SUCCESS;
    },
    isStatusNeutral() {
      return this.status === STATUS_NEUTRAL;
    },
  },
};
</script>
<template>
  <div
    :class="{
      failed: isStatusFailed,
      success: isStatusSuccess,
      neutral: isStatusNeutral,
    }"
    class="report-block-list-icon"
  >
    <gl-icon :name="iconName" :size="statusIconSize" />
  </div>
</template>
