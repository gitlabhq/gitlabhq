<script>
import { GlBadge } from '@gitlab/ui';
import { __ } from '~/locale';

const badgeVariants = {
  onTrack: 'success',
  needsAttention: 'warning',
  atRisk: 'danger',
};

const badgeLabels = {
  onTrack: __('On track'),
  needsAttention: __('Needs attention'),
  atRisk: __('At risk'),
};

export default {
  name: 'HealthPresenter',
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
  },
};
</script>
<template>
  <gl-badge :variant="badgeVariant">{{ badgeLabel }}</gl-badge>
</template>
