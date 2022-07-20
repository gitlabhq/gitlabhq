<script>
import { s__ } from '~/locale';
import StatusIcon from '../mr_widget_status_icon.vue';

export default {
  i18n: {
    approvalNeeded: s__('mrWidget|Merge blocked: all required approvals must be given.'),
    blockingMergeRequests: s__(
      'mrWidget|Merge blocked: you can only merge after the above items are resolved.',
    ),
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
      } else if (this.mr.blockingMergeRequests?.total_count > 0) {
        return this.$options.i18n.blockingMergeRequests;
      }

      return null;
    },
  },
};
</script>

<template>
  <div class="mr-widget-body media gl-flex-wrap">
    <status-icon status="warning" />
    <p class="media-body gl-m-0! gl-font-weight-bold gl-text-black-normal!">
      {{ failedText }}
    </p>
  </div>
</template>
