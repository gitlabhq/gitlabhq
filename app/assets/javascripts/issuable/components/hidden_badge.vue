<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';

export default {
  components: {
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
};
</script>

<template>
  <gl-badge
    v-gl-tooltip
    icon="spam"
    :title="s__('WorkItem|This item is hidden because its author has been banned.')"
    :aria-label="__('Hidden')"
    variant="warning"
    class="gl-shrink-0"
  />
</template>
