<script>
import { GlIcon } from '@gitlab/ui';
import { formatTime } from '~/lib/utils/datetime_utility';
import CiBadgeLink from '~/vue_shared/components/ci_badge_link.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  iconSize: 12,
  components: {
    CiBadgeLink,
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
    hasDurationAndFinishedTime() {
      return this.finishedTime && this.duration;
    },
  },
};
</script>

<template>
  <div>
    <ci-badge-link :status="job.detailedStatus" />
    <div class="gl-font-sm gl-text-secondary gl-mt-2 gl-ml-3">
      <div v-if="duration" data-testid="job-duration">
        <gl-icon name="timer" :size="$options.iconSize" data-testid="duration-icon" />
        {{ durationFormatted }}
      </div>
      <div v-if="finishedTime" data-testid="job-finished-time">
        <gl-icon name="calendar" :size="$options.iconSize" data-testid="finished-time-icon" />
        <time-ago-tooltip :time="finishedTime" />
      </div>
    </div>
  </div>
</template>
