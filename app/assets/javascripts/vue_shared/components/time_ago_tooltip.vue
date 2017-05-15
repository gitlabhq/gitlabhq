<script>
import tooltipMixin from '../mixins/tooltip';
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

    htmlClass: {
      type: String,
      required: false,
      default: '',
    },
  },

  mixins: [tooltipMixin],

  computed: {
    cssClass() {
      return this.shortFormat ? 'js-short-timeago' : 'js-timeago';
    },

    tooltipTitle() {
      return gl.utils.formatDate(this.time);
    },

    timeFormated() {
      const timeago = gl.utils.getTimeago();

      return timeago.format(this.time);
    },
  },
};
</script>

<template>
  <time
    :class="[cssClass, htmlClass]"
    class="js-timeago js-timeago-render"
    :title="tooltipTitle"
    :data-placement="tooltipPlacement"
    data-container="body"
    ref="tooltip"
  >
    {{timeFormated}}
  </time>
</template>
