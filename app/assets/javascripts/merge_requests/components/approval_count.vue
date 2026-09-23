<script>
import { GlBadge, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { __, n__ } from '~/locale';

export default {
  name: 'ApprovalCount',
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
    fullText: {
      type: Boolean,
      required: false,
      default: false,
    },
    /**
     * Renders a subtle icon and count instead of the badge, for dense lists where a
     * coloured pill would compete with the merge request title for attention.
     */
    neutral: {
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
  <button
    v-if="approvalCount"
    v-gl-tooltip.viewport.top="tooltipTitle"
    :aria-label="tooltipTitle"
    class="!gl-cursor-default gl-rounded-pill gl-border-none gl-bg-transparent gl-p-0"
    data-testid="mr-approvals"
  >
    <span v-if="neutral" class="gl-flex gl-items-center gl-gap-2 gl-text-sm gl-text-subtle">
      <gl-icon name="approval" :size="12" variant="subtle" />{{ approvalCount }}
    </span>
    <gl-badge v-else icon="check-circle" variant="success" icon-optically-aligned>
      {{ approvalCount }}
    </gl-badge>
  </button>
</template>
