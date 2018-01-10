<script>
import tooltip from '../directives/tooltip';
import timeagoMixin from '../mixins/timeago';
import '../../lib/utils/datetime_utility';

/**
 * Port of ruby helper time_ago_with_tooltip
 */

export default {
  directives: {
    tooltip,
  },
  mixins: [
    timeagoMixin,
  ],
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
    v-tooltip
    :class="cssClass"
    :title="tooltipTitle(time)"
    :data-placement="tooltipPlacement"
    data-container="body">
    {{ timeFormated(time) }}
  </time>
</template>
