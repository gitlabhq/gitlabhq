<script>
import { formatDate } from '~/lib/utils/datetime_utility';
import timeAgoMixin from '~/vue_shared/mixins/timeago';
import tooltip from '~/vue_shared/directives/tooltip';

export default {
  props: {
    eventId: {
      type: Number,
      required: true,
    },
    eventTimeStamp: {
      type: Number,
      required: true,
    },
  },
  mixins: [
    timeAgoMixin,
  ],
  directives: {
    tooltip,
  },
  computed: {
    timeStamp() {
      return new Date(this.eventTimeStamp * 1000);
    },
    timeStampString() {
      return formatDate(this.timeStamp);
    },
  },
};
</script>

<template>
  <div
    class="node-detail-value"
  >
    <strong>
      {{eventId}}
    </strong>
    <span
      v-tooltip
      class="event-status-timestamp"
      data-placement="bottom"
      :title="timeStampString"
    >
      ({{timeFormated(timeStamp)}})
    </span>
  </div>
</template>
