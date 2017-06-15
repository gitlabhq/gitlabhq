<script>
  import iconTimerSvg from 'icons/_icon_timer.svg';
  import '../../lib/utils/datetime_utility';
  import tooltipMixin from '../../vue_shared/mixins/tooltip';
  import timeagoMixin from '../../vue_shared/mixins/timeago';

  export default {
    props: {
      finishedTime: {
        type: String,
        required: true,
      },
      duration: {
        type: Number,
        required: true,
      },
    },
    mixins: [
      tooltipMixin,
      timeagoMixin,
    ],
    data() {
      return {
        iconTimerSvg,
      };
    },
    computed: {
      hasDuration() {
        return this.duration > 0;
      },
      hasFinishedTime() {
        return this.finishedTime !== '';
      },
      durationFormated() {
        const date = new Date(this.duration * 1000);

        let hh = date.getUTCHours();
        let mm = date.getUTCMinutes();
        let ss = date.getSeconds();

        // left pad
        if (hh < 10) {
          hh = `0${hh}`;
        }
        if (mm < 10) {
          mm = `0${mm}`;
        }
        if (ss < 10) {
          ss = `0${ss}`;
        }

        return `${hh}:${mm}:${ss}`;
      },
    },
  };
</script>
<template>
  <td class="pipelines-time-ago">
    <p
      class="duration"
      v-if="hasDuration">
      <span v-html="iconTimerSvg">
      </span>
      {{durationFormated}}
    </p>

    <p
      class="finished-at"
      v-if="hasFinishedTime">

      <i
        class="fa fa-calendar"
        aria-hidden="true">
      </i>

      <time
        ref="tooltip"
        data-placement="top"
        data-container="body"
        :title="tooltipTitle(finishedTime)">
        {{timeFormated(finishedTime)}}
      </time>
    </p>
  </td>
</script>
