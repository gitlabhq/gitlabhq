<script>
import { GlBadge, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import { STATE_OPEN } from '../constants';

export default {
  components: {
    GlBadge,
    GlIcon,
  },
  props: {
    workItemState: {
      type: String,
      required: true,
    },
  },
  computed: {
    isWorkItemOpen() {
      return this.workItemState === STATE_OPEN;
    },
    stateText() {
      return this.isWorkItemOpen ? __('Open') : __('Closed');
    },
    workItemStateIcon() {
      return this.isWorkItemOpen ? 'issue-open-m' : 'issue-close';
    },
    workItemStateVariant() {
      return this.isWorkItemOpen ? 'success' : 'info';
    },
  },
};
</script>

<template>
  <gl-badge :variant="workItemStateVariant" class="gl-align-middle">
    <gl-icon :name="workItemStateIcon" :size="16" />
    {{ stateText }}
  </gl-badge>
</template>
