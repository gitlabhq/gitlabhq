<script>
import { GlBadge } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'ProjectListItemInactiveBadge',
  i18n: {
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
    inactiveBadge() {
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
