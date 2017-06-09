<script>
import tooltipMixin from '../mixins/tooltip';
<<<<<<< HEAD
=======
import timeagoMixin from '../mixins/timeago';
>>>>>>> abc61f260074663e5711d3814d9b7d301d07a259
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

<<<<<<< HEAD
    htmlClass: {
=======
    cssClass: {
>>>>>>> abc61f260074663e5711d3814d9b7d301d07a259
      type: String,
      required: false,
      default: '',
    },
  },

<<<<<<< HEAD
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
=======
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
>>>>>>> abc61f260074663e5711d3814d9b7d301d07a259
  </time>
</template>
