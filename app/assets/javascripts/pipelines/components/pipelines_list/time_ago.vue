<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { formatTime } from '~/lib/utils/datetime_utility';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: { GlIcon },
  mixins: [timeagoMixin],
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
  },
  computed: {
    duration() {
      return this.pipeline?.details?.duration;
    },
    durationFormatted() {
      return formatTime(this.duration * 1000);
    },
    finishedTime() {
      return this.pipeline?.details?.finished_at;
    },
    showInProgress() {
      return !this.duration && !this.finishedTime && !this.skipped;
    },
    showSkipped() {
      return !this.duration && !this.finishedTime && this.skipped;
    },
    skipped() {
      return this.pipeline?.details?.status?.label === 'skipped';
    },
    stuck() {
      return this.pipeline.flags.stuck;
    },
  },
};
</script>
<template>
  <div class="gl-display-flex gl-flex-direction-column gl-font-sm time-ago">
    <span
      v-if="showInProgress"
      class="gl-display-inline-flex gl-align-items-center"
      data-testid="pipeline-in-progress"
    >
      <gl-icon v-if="stuck" name="warning" class="gl-mr-2" :size="12" data-testid="warning-icon" />
      <gl-icon v-else name="hourglass" class="gl-mr-2" :size="12" data-testid="hourglass-icon" />
      {{ s__('Pipeline|In progress') }}
    </span>

    <span v-if="showSkipped" data-testid="pipeline-skipped">
      <gl-icon name="status_skipped_borderless" />
      {{ s__('Pipeline|Skipped') }}
    </span>

    <p v-if="duration" class="duration gl-display-inline-flex gl-align-items-center">
      <gl-icon name="timer" class="gl-mr-2" :size="12" />
      {{ durationFormatted }}
    </p>

    <p v-if="finishedTime" class="finished-at gl-display-inline-flex gl-align-items-center">
      <gl-icon name="calendar" class="gl-mr-2" :size="12" />

      <time
        v-gl-tooltip
        :title="tooltipTitle(finishedTime)"
        :datetime="finishedTime"
        data-placement="top"
        data-container="body"
      >
        {{ timeFormatted(finishedTime) }}
      </time>
    </p>
  </div>
</template>
