<script>
import { GlTooltipDirective } from '@gitlab/ui';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    count: {
      type: Number,
      required: true,
    },
  },
};
</script>
<template>
  <span v-if="count === 50" class="events-info float-right">
    <i
      v-gl-tooltip
      :title="
        n__('Limited to showing %d event at most', 'Limited to showing %d events at most', 50)
      "
      class="fa fa-warning"
      aria-hidden="true"
    >
    </i>
    {{ n__('Showing %d event', 'Showing %d events', 50) }}
  </span>
</template>
