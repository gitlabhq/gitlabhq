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
      type: [String, Number],
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
  computed: {
    timeAgo() {
      return this.timeFormatted(this.time);
    },
  },
};
</script>
<template>
  <time
    v-gl-tooltip.viewport="{ placement: tooltipPlacement }"
    :class="cssClass"
    :title="tooltipTitle(time)"
    :datetime="time"
    ><slot :timeAgo="timeAgo">{{ timeAgo }}</slot></time
  >
</template>
