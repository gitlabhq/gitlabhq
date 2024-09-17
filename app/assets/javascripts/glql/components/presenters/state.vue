<script>
import { GlBadge } from '@gitlab/ui';
import { __ } from '~/locale';

const badgeVariants = { opened: 'success', closed: 'info' };
const badgeLabels = { opened: __('Open'), closed: __('Closed') };
const badgeIcons = { opened: 'issue-open-m', closed: 'issue-close' };

export default {
  name: 'StatePresenter',
  components: {
    GlBadge,
  },
  props: {
    data: {
      required: true,
      type: String,
    },
  },
  computed: {
    badgeVariant() {
      return badgeVariants[this.data];
    },
    badgeLabel() {
      return badgeLabels[this.data];
    },
    badgeIcon() {
      return badgeIcons[this.data];
    },
  },
};
</script>
<template>
  <gl-badge :variant="badgeVariant" :icon="badgeIcon">{{ badgeLabel }}</gl-badge>
</template>
