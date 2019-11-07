<script>
import Icon from '~/vue_shared/components/icon.vue';
import { STATUS_FAILED, STATUS_NEUTRAL, STATUS_SUCCESS } from '../constants';

export default {
  name: 'IssueStatusIcon',
  components: {
    Icon,
  },
  props: {
    // failed || success
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
      } else if (this.isStatusSuccess) {
        return 'status_success_borderless';
      }

      return 'status_created_borderless';
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
    <icon :name="iconName" :size="statusIconSize" :data-qa-selector="`status_${status}_icon`" />
  </div>
</template>
