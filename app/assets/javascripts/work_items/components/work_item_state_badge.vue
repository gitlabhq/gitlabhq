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
  <gl-badge
    :icon="workItemStateIcon"
    :variant="workItemStateVariant"
    class="gl-mr-2 gl-vertical-align-middle"
  >
    {{ stateText }}
  </gl-badge>
</template>
