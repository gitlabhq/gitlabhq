<script>
  import { formatDate } from '~/lib/utils/datetime_utility';
  import timeAgoMixin from '~/vue_shared/mixins/timeago';
  import tooltip from '~/vue_shared/directives/tooltip';

  export default {
    directives: {
      tooltip,
    },
    mixins: [
      timeAgoMixin,
    ],
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
    <template v-if="eventTimeStamp">
      <strong>
        {{ eventId }}
      </strong>
      <span
        v-tooltip
        v-if="eventTimeStamp"
        class="event-status-timestamp"
        data-placement="bottom"
        :title="timeStampString"
      >
        ({{ timeFormated(timeStamp) }})
      </span>
    </template>
    <strong
      v-else
    >
      {{ __('Not available') }}
    </strong>
  </div>
</template>
