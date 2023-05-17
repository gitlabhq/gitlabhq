<script>
import { GlTooltipDirective } from '@gitlab/ui';

import { DATE_TIME_FORMATS, DEFAULT_DATE_TIME_FORMAT } from '~/lib/utils/datetime_utility';
import timeagoMixin from '../mixins/timeago';

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
      type: [String, Number, Date],
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
    dateTimeFormat: {
      type: String,
      required: false,
      default: DEFAULT_DATE_TIME_FORMAT,
      validator: (timeFormat) => DATE_TIME_FORMATS.includes(timeFormat),
    },
  },
  computed: {
    timeAgo() {
      return this.timeFormatted(this.time, this.dateTimeFormat);
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
    ><slot :time-ago="timeAgo">{{ timeAgo }}</slot></time
  >
</template>
