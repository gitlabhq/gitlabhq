<script>
import { GlTooltipDirective } from '@gitlab/ui';
import timeagoMixin from '../mixins/timeago';
import '../../lib/utils/datetime_utility';

/**
 * Port of ruby helper time_ago_with_tooltip
 */

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  props: {
    time: {
      type: String,
      required: true,
    },
    tooltipPlacement: {
      type: String,
      required: false,
      default: 'top',
    },
    cssClass: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>
<template>
  <time
    v-gl-tooltip.viewport="{ placement: tooltipPlacement }"
    :class="cssClass"
    :title="tooltipTitle(time)"
    v-text="timeFormatted(time)"
  >
  </time>
</template>
