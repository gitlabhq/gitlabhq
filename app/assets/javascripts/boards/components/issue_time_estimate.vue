<script>
import { GlTooltip } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import { parseSeconds, stringifyTime } from '~/lib/utils/datetime_utility';
import boardsStore from '../stores/boards_store';

export default {
  components: {
    Icon,
    GlTooltip,
  },
  props: {
    estimate: {
      type: Number,
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
      <icon name="hourglass" css-classes="board-card-info-icon align-top" /><time
        class="board-card-info-text"
        >{{ timeEstimate }}</time
      >
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
