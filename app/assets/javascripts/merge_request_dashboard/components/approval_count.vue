<script>
import { GlBadge, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { n__ } from '~/locale';

export default {
  components: {
    GlBadge,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    mergeRequest: {
      type: Object,
      required: true,
    },
  },
  computed: {
    approvalCount() {
      return this.mergeRequest.approvedBy.nodes.length;
    },
    tooltipTitle() {
      return n__('%d approval', '%d approvals', this.approvalCount);
    },
  },
};
</script>

<template>
  <gl-badge
    v-if="approvalCount"
    v-gl-tooltip.viewport.top="tooltipTitle"
    icon="check-circle"
    variant="success"
  >
    {{ approvalCount }}
  </gl-badge>
  <gl-icon v-else name="dash" />
</template>
