<script>
import tooltipMixin from '../mixins/tooltip';
import timeagoMixin from '../mixins/timeago';
import '../../lib/utils/datetime_utility';

/**
 * Port of ruby helper time_ago_with_tooltip
 */

export default {
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

  mixins: [
    tooltipMixin,
    timeagoMixin,
  ],
};
</script>
<template>
  <time
    :class="cssClass"
    class="js-vue-timeago"
    :title="tooltipTitle(time)"
    :data-placement="tooltipPlacement"
    data-container="body"
    ref="tooltip">
    {{timeFormated(time)}}
  </time>
</template>
