<script>
import { s__ } from '~/locale';
import StateContainer from '../state_container.vue';
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
    StateContainer,
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
  <state-container :mr="mr" status="failed">
    <span
      class="gl-ml-3 gl-font-weight-bold gl-w-100 gl-flex-grow-1 gl-md-mr-3 gl-ml-0! gl-text-body!"
    >
      {{ failedText }}
    </span>
  </state-container>
</template>
