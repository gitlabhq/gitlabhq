<script>
import { GlBadge } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'GroupListItemInactiveBadge',
  i18n: {
    deletionInProgress: __('Deletion in progress'),
    pendingDeletion: __('Pending deletion'),
  },
  components: {
    GlBadge,
  },
  props: {
    group: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isSelfDeletionInProgress() {
      return Boolean(this.group.isSelfDeletionInProgress);
    },
    isPendingDeletion() {
      return Boolean(this.group.markedForDeletion);
    },
    inactiveBadge() {
      if (this.isSelfDeletionInProgress) {
        return {
          variant: 'warning',
          text: this.$options.i18n.deletionInProgress,
        };
      }

      if (this.isPendingDeletion) {
        return {
          variant: 'warning',
          text: this.$options.i18n.pendingDeletion,
        };
      }

      return null;
    },
  },
};
</script>

<template>
  <gl-badge v-if="inactiveBadge" :variant="inactiveBadge.variant">{{
    inactiveBadge.text
  }}</gl-badge>
</template>
