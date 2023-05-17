<script>
import { GlTooltip, GlIcon } from '@gitlab/ui';
import { parseSeconds, stringifyTime } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';

export default {
  i18n: {
    timeEstimate: __('Time estimate'),
  },
  components: {
    GlIcon,
    GlTooltip,
  },
  inject: ['timeTrackingLimitToHours'],
  props: {
    estimate: {
      type: Number,
      required: true,
    },
  },
  computed: {
    title() {
      return stringifyTime(
        parseSeconds(this.estimate, { limitToHours: this.timeTrackingLimitToHours }),
        true,
      );
    },
    timeEstimate() {
      return stringifyTime(
        parseSeconds(this.estimate, { limitToHours: this.timeTrackingLimitToHours }),
      );
    },
  },
};
</script>

<template>
  <span>
    <span ref="issueTimeEstimate" class="board-card-info gl-mr-3 gl-text-secondary gl-cursor-help">
      <gl-icon name="hourglass" class="board-card-info-icon gl-mr-2" />
      <time class="gl-font-sm board-card-info-text">{{ timeEstimate }}</time>
    </span>
    <gl-tooltip
      :target="() => $refs.issueTimeEstimate"
      placement="bottom"
      data-testid="issue-time-estimate"
    >
      <span class="gl-font-weight-bold gl-display-block">{{ $options.i18n.timeEstimate }}</span>
      {{ title }}
    </gl-tooltip>
  </span>
</template>
