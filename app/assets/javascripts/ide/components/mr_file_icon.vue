<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
};
</script>

<template>
  <gl-icon
    v-gl-tooltip
    :title="__('Part of merge request changes')"
    :size="12"
    name="merge-request"
    class="gl-mr-3"
  />
</template>
