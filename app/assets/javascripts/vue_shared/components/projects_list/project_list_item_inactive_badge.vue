<script>
import { GlBadge } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'ProjectListItemInactiveBadge',
  i18n: {
    pendingDeletion: __('Pending deletion'),
    archived: __('Archived'),
  },
  components: {
    GlBadge,
  },
  props: {
    project: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isPendingDeletion() {
      return Boolean(this.project.markedForDeletionOn);
    },
    inactiveBadge() {
      if (this.isPendingDeletion) {
        return {
          variant: 'warning',
          text: this.$options.i18n.pendingDeletion,
        };
      }

      if (this.project.archived) {
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
