<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { formatTime } from '~/lib/utils/datetime_utility';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  name: 'PipelinesTimeago',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
  },
  mixins: [timeagoMixin],
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
  },
  computed: {
    duration() {
      return this.pipeline?.details?.duration ?? this.pipeline?.duration;
    },
    durationFormatted() {
      if (typeof this.duration === 'number') {
        return formatTime(this.duration * 1000);
      }
      return '';
    },
    finishedTime() {
      return this.pipeline?.details?.finished_at || this.pipeline?.finishedAt;
    },
  },
};
</script>
<template>
  <div class="gl-text-sm gl-text-subtle">
    <p v-if="durationFormatted" class="gl-mb-0 gl-whitespace-nowrap" data-testid="duration">
      <gl-icon name="timer" class="gl-mr-2" :size="12" variant="subtle" />
      {{ durationFormatted }}
    </p>

    <p v-if="finishedTime" class="gl-mb-0 gl-whitespace-nowrap" data-testid="finished-at">
      <gl-icon
        name="calendar"
        class="gl-mr-2"
        :size="12"
        data-testid="calendar-icon"
        variant="subtle"
      />
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
