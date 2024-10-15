<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';

export default {
  name: 'ProtectedBadge',
  components: { GlBadge },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    tooltipText: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <gl-badge v-gl-tooltip :title="tooltipText" size="sm" variant="neutral">
    {{ __('protected') }}
  </gl-badge>
</template>
