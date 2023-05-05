<script>
import { GlIcon } from '@gitlab/ui';
import { formatTime } from '~/lib/utils/datetime_utility';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  iconSize: 12,
  components: {
    GlIcon,
    TimeAgoTooltip,
  },
  mixins: [timeagoMixin],
  props: {
    job: {
      type: Object,
      required: true,
    },
  },
  computed: {
    finishedTime() {
      return this.job?.finishedAt;
    },
    duration() {
      return this.job?.duration;
    },
    durationFormatted() {
      return formatTime(this.duration * 1000);
    },
  },
};
</script>

<template>
  <div>
    <div v-if="duration" data-testid="job-duration">
      <gl-icon name="timer" :size="$options.iconSize" data-testid="duration-icon" />
      {{ durationFormatted }}
    </div>
    <div v-if="finishedTime" data-testid="job-finished-time">
      <gl-icon name="calendar" :size="$options.iconSize" data-testid="finished-time-icon" />
      <time-ago-tooltip :time="finishedTime" />
    </div>
  </div>
</template>
