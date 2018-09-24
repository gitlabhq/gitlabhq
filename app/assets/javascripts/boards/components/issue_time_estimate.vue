<script>
import tooltip from '~/vue_shared/directives/tooltip';
import Icon from '~/vue_shared/components/icon.vue';
import { sprintf, __ } from '~/locale';
import { parseSeconds, stringifyTime } from '~/lib/utils/pretty_time';

export default {
  components: {
    Icon,
  },
  directives: {
    tooltip,
  },
  props: {
    estimate: {
      type: Number,
      required: true,
    },
  },
  computed: {
    title() {
      return `<span class="bold">${__('Time estimate')}</span> <br> ${sprintf(__('%{estimate}'), {
        estimate: stringifyTime(parseSeconds(this.estimate), true),
      })}`;
    },
    timeEstimate() {
      return stringifyTime(parseSeconds(this.estimate));
    },
  },
};
</script>

<template>
  <span
    v-tooltip
    :title="title"
    class="board-card-info card-number"
    data-html="true"
    data-placement="bottom"
    data-container="body"
  >
    <icon name="hourglass"/><time class="board-card-info-text">{{ timeEstimate }}</time>
  </span>
</template>
