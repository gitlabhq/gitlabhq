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
    fontSize: {
      type: String,
      required: false,
      default: 'gl-text-sm',
      validator: (fontSize) => ['gl-text-sm', 'gl-font-md'].includes(fontSize),
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
      return this.pipeline?.details?.finished_at || this.pipeline?.finishedAt;
    },
  },
};
</script>
<template>
  <div class="gl-flex gl-flex-col gl-items-end lg:gl-items-start" :class="fontSize">
    <p
      v-if="duration"
      class="gl-m-0 gl-inline-flex gl-items-center gl-whitespace-nowrap gl-text-subtle"
      data-testid="duration"
    >
      <gl-icon name="timer" class="gl-mr-2" :size="12" variant="subtle" />
      {{ durationFormatted }}
    </p>

    <p
      v-if="finishedTime"
      class="gl-m-0 gl-inline-flex gl-items-center gl-whitespace-nowrap gl-text-subtle"
      data-testid="finished-at"
    >
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
