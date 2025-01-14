<script>
import { isHealthStatusWidget } from '~/work_items/utils';

export default {
  components: {
    IssueHealthStatus: () =>
      import('ee_component/related_items_tree/components/issue_health_status.vue'),
  },
  inject: ['hasIssuableHealthStatusFeature'],
  props: {
    issue: {
      type: Object,
      required: true,
    },
  },
  computed: {
    healthStatus() {
      return (
        this.issue.healthStatus || this.issue.widgets?.find(isHealthStatusWidget)?.healthStatus
      );
    },
    hasUpdateTimeStamp() {
      return this.issue.updatedAt !== this.issue.createdAt;
    },
    showHealthStatus() {
      return this.hasIssuableHealthStatusFeature && this.healthStatus;
    },
  },
};
</script>

<template>
  <issue-health-status
    v-if="showHealthStatus"
    class="gl-text-nowrap"
    display-as-text
    text-size="sm"
    :class="{
      'md:gl-border-r md:gl-mr-3 md:gl-border-gray-100 md:gl-pr-3': hasUpdateTimeStamp,
    }"
    :health-status="healthStatus"
  />
</template>
