<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { formatDate, getTimeago, durationTimeFormatted } from '~/lib/utils/datetime_utility';

export default {
  iconSize: 12,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
  },
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
    timeFormatted() {
      return getTimeago().format(this.finishedTime);
    },
    tooltipTitle() {
      return formatDate(this.finishedTime);
    },
    durationFormatted() {
      return durationTimeFormatted(this.duration);
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
      <time
        v-gl-tooltip
        :title="tooltipTitle"
        :datetime="finishedTime"
        data-placement="top"
        data-container="body"
      >
        {{ timeFormatted }}
      </time>
    </div>
  </div>
</template>
