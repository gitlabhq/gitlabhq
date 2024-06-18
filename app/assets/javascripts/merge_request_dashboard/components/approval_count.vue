<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { n__ } from '~/locale';

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
  },
  computed: {
    hasApprovers() {
      return this.mergeRequest.approvedBy.nodes.length;
    },
    tooltipTitle() {
      return n__('%d approver', '%d approvers', this.mergeRequest.approvedBy.nodes.length);
    },
  },
};
</script>

<template>
  <gl-badge v-if="hasApprovers" v-gl-tooltip="tooltipTitle" icon="approval" variant="success">
    {{ __('Approved') }}
  </gl-badge>
</template>
