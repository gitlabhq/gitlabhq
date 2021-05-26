<script>
import { GlTooltip, GlIcon } from '@gitlab/ui';
import { parseSeconds, stringifyTime } from '~/lib/utils/datetime_utility';
import boardsStore from '../stores/boards_store';

export default {
  components: {
    GlIcon,
    GlTooltip,
  },
  props: {
    estimate: {
      type: [Number, String],
      required: true,
    },
  },
  data() {
    return {
      limitToHours: boardsStore.timeTracking.limitToHours,
    };
  },
  computed: {
    title() {
      return stringifyTime(parseSeconds(this.estimate, { limitToHours: this.limitToHours }), true);
    },
    timeEstimate() {
      return stringifyTime(parseSeconds(this.estimate, { limitToHours: this.limitToHours }));
    },
  },
};
</script>

<template>
  <span>
    <span ref="issueTimeEstimate" class="board-card-info card-number">
      <gl-icon name="hourglass" class="board-card-info-icon" /><time class="board-card-info-text">{{
        timeEstimate
      }}</time>
    </span>
    <gl-tooltip
      :target="() => $refs.issueTimeEstimate"
      placement="bottom"
      class="js-issue-time-estimate"
    >
      <span class="bold d-block">{{ __('Time estimate') }}</span> {{ title }}
    </gl-tooltip>
  </span>
</template>
