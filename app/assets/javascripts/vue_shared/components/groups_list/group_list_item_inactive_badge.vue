<script>
import { GlBadge } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'GroupListItemInactiveBadge',
  i18n: {
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
    isPendingDeletion() {
      return Boolean(this.group.markedForDeletionOn);
    },
    inactiveBadge() {
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
