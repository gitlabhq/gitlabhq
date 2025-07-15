<script>
import { GlLink, GlTruncate, GlTooltipDirective } from '@gitlab/ui';

import { DATE_TIME_FORMATS, DEFAULT_DATE_TIME_FORMAT } from '~/lib/utils/datetime_utility';
import timeagoMixin from '../mixins/timeago';

/**
 * Port of ruby helper time_ago_with_tooltip
 */

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlLink,
    GlTruncate,
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
    enableTruncation: {
      type: Boolean,
      required: false,
      default: false,
    },
    showDateWhenOverAYear: {
      type: Boolean,
      required: false,
      default: true,
    },
    href: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    timeAgo() {
      return this.timeFormatted(this.time, this.dateTimeFormat, {
        showDateWhenOverAYear: this.showDateWhenOverAYear,
      });
    },
    tooltipText() {
      return this.enableTruncation ? undefined : this.tooltipTitle(this.time);
    },
  },
};
</script>
<template>
  <gl-link
    v-if="href"
    v-gl-tooltip.viewport="{ placement: tooltipPlacement }"
    :href="href"
    :title="tooltipText"
    :aria-label="tooltipText"
    @click="$emit('click', $event)"
  >
    <time :class="cssClass" :datetime="time"
      ><slot :time-ago="timeAgo"
        ><template v-if="enableTruncation"><gl-truncate :text="timeAgo" with-tooltip /></template
        ><template v-else>{{ timeAgo }}</template></slot
      ></time
    >
  </gl-link>
  <time
    v-else
    v-gl-tooltip.viewport="{ placement: tooltipPlacement }"
    tabindex="0"
    :class="cssClass"
    :title="tooltipText"
    :aria-label="tooltipText"
    :datetime="time"
    ><slot :time-ago="timeAgo"
      ><template v-if="enableTruncation"><gl-truncate :text="timeAgo" with-tooltip /></template
      ><template v-else>{{ timeAgo }}</template></slot
    ></time
  >
</template>
