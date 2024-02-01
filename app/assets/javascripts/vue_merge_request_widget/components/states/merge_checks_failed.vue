<script>
import { s__ } from '~/locale';
import BoldText from '~/vue_merge_request_widget/components/bold_text.vue';
import StateContainer from '../state_container.vue';
import { DETAILED_MERGE_STATUS } from '../../constants';

export default {
  i18n: {
    approvalNeeded: s__(
      'mrWidget|%{boldStart}Merge blocked:%{boldEnd} all required approvals must be given.',
    ),
    blockingMergeRequests: s__(
      'mrWidget|%{boldStart}Merge blocked:%{boldEnd} you can only merge after the above items are resolved.',
    ),
    externalStatusChecksFailed: s__(
      'mrWidget|%{boldStart}Merge blocked:%{boldEnd} all status checks must pass.',
    ),
  },
  components: {
    BoldText,
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
      }
      if (this.mr.detailedMergeStatus === DETAILED_MERGE_STATUS.BLOCKED_STATUS) {
        return this.$options.i18n.blockingMergeRequests;
      }
      if (this.mr.detailedMergeStatus === DETAILED_MERGE_STATUS.EXTERNAL_STATUS_CHECKS) {
        return this.$options.i18n.externalStatusChecksFailed;
      }

      return null;
    },
  },
};
</script>

<template>
  <state-container
    status="failed"
    is-collapsible
    :collapsed="mr.mergeDetailsCollapsed"
    @toggle="() => mr.toggleMergeDetails()"
  >
    <span class="gl-ml-3 gl-gl-w-full gl-flex-grow-1 gl-md-mr-3 gl-ml-0! gl-text-body!">
      <bold-text :message="failedText" />
    </span>
  </state-container>
</template>
