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

    shortFormat: {
      type: Boolean,
      required: false,
      default: false,
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

  computed: {
    timeagoCssClass() {
      return this.shortFormat ? 'js-short-timeago' : 'js-timeago';
    },
  },
};
</script>
<template>
  <time
    :class="[timeagoCssClass, cssClass]"
    class="js-timeago js-timeago-render"
    :title="tooltipTitle(time)"
    :data-placement="tooltipPlacement"
    data-container="body"
    ref="tooltip">
    {{timeFormated(time)}}
  </time>
</template>
