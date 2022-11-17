<script>
import { s__ } from '~/locale';
import StatusIcon from '../mr_widget_status_icon.vue';
import { DETAILED_MERGE_STATUS } from '../../constants';

export default {
  i18n: {
    approvalNeeded: s__('mrWidget|Merge blocked: all required approvals must be given.'),
    blockingMergeRequests: s__(
      'mrWidget|Merge blocked: you can only merge after the above items are resolved.',
    ),
    externalStatusChecksFailed: s__('mrWidget|Merge blocked: all status checks must pass.'),
  },
  components: {
    StatusIcon,
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  computed: {
    failedText() {
      if (this.mr.approvals && !this.mr.isApproved) {
        return this.$options.i18n.approvalNeeded;
      } else if (this.mr.detailedMergeStatus === DETAILED_MERGE_STATUS.BLOCKED_STATUS) {
        return this.$options.i18n.blockingMergeRequests;
      } else if (this.mr.detailedMergeStatus === DETAILED_MERGE_STATUS.EXTERNAL_STATUS_CHECKS) {
        return this.$options.i18n.externalStatusChecksFailed;
      }

      return null;
    },
  },
};
</script>

<template>
  <div class="mr-widget-body media gl-flex-wrap">
    <status-icon status="failed" />
    <p class="media-body gl-m-0! gl-font-weight-bold gl-text-black-normal!">
      {{ failedText }}
    </p>
  </div>
</template>
