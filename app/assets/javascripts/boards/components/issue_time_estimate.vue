<script>
import { GlTooltip } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import { parseSeconds, stringifyTime } from '~/lib/utils/datetime_utility';

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
  computed: {
    title() {
      return stringifyTime(parseSeconds(this.estimate), true);
    },
    timeEstimate() {
      return stringifyTime(parseSeconds(this.estimate));
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
