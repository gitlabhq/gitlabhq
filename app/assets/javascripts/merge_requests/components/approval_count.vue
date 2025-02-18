<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { __, n__ } from '~/locale';

export default {
  components: {
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    mergeRequest: {
      type: Object,
      required: true,
    },
    fullText: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    approvalCount() {
      if (this.fullText && this.mergeRequest.approvedBy.nodes.length) {
        return __('Approved');
      }

      return this.mergeRequest.approvedBy.nodes.length;
    },
    tooltipTitle() {
      return n__('%d approval', '%d approvals', this.mergeRequest.approvedBy.nodes.length);
    },
  },
};
</script>

<template>
  <gl-badge
    v-if="approvalCount"
    v-gl-tooltip.viewport.top="tooltipTitle"
    :aria-label="tooltipTitle"
    icon="check-circle"
    variant="success"
    icon-optically-aligned
    data-testid="mr-appovals"
  >
    {{ approvalCount }}
  </gl-badge>
</template>
