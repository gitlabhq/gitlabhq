<script>
import { GlBadge } from '@gitlab/ui';
import { __ } from '~/locale';
import { STATE_OPEN } from '../constants';

export default {
  components: {
    GlBadge,
  },
  props: {
    workItemState: {
      type: String,
      required: true,
    },
    showIcon: {
      type: Boolean,
      required: false,
      default: true,
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
      if (!this.showIcon) {
        return null;
      }

      return this.isWorkItemOpen ? 'issue-open-m' : 'issue-close';
    },
    workItemStateVariant() {
      return this.isWorkItemOpen ? 'success' : 'info';
    },
  },
};
</script>

<template>
  <gl-badge :variant="workItemStateVariant" :icon="workItemStateIcon" class="gl-align-middle">
    {{ stateText }}
  </gl-badge>
</template>
