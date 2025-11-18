<script>
import { findHealthStatusWidget } from '~/work_items/utils';

export default {
  components: {
    IssueHealthStatus: () => import('ee_component/issues/components/issue_health_status.vue'),
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
      return this.issue.healthStatus || findHealthStatusWidget(this.issue)?.healthStatus;
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
      '@md/panel:gl-border-r @md/panel:gl-mr-3 @md/panel:gl-border-gray-100 @md/panel:gl-pr-3':
        hasUpdateTimeStamp,
    }"
    :health-status="healthStatus"
  />
</template>
