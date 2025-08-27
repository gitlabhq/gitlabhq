<script>
import { GlBadge } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  i18n: {
    deletionInProgress: __('Deletion in progress'),
    pendingDeletion: __('Pending deletion'),
    archived: __('Archived'),
  },
  components: {
    GlBadge,
  },
  props: {
    resource: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isSelfDeletionInProgress() {
      return Boolean(this.resource.isSelfDeletionInProgress);
    },
    isPendingDeletion() {
      return Boolean(this.resource.markedForDeletion);
    },
    isArchived() {
      return this.resource.archived;
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

      if (this.isArchived) {
        return {
          variant: 'info',
          text: this.$options.i18n.archived,
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
