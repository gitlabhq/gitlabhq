<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  iconSize: 12,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
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
  },
};
</script>

<template>
  <div>
    <div v-if="duration" data-testid="job-duration">
      <gl-icon name="timer" :size="$options.iconSize" data-testid="duration-icon" />
      {{ durationTimeFormatted(duration) }}
    </div>
    <div v-if="finishedTime" data-testid="job-finished-time">
      <gl-icon name="calendar" :size="$options.iconSize" data-testid="finished-time-icon" />
      <time
        v-gl-tooltip
        :title="tooltipTitle(finishedTime)"
        data-placement="top"
        data-container="body"
      >
        {{ timeFormatted(finishedTime) }}
      </time>
    </div>
  </div>
</template>
