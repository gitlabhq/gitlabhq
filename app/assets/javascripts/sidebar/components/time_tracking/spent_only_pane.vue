<script>
import { sprintf, s__ } from '~/locale';

export default {
  name: 'TimeTrackingSpentOnlyPane',
  props: {
    timeSpentHumanReadable: {
      type: String,
      required: true,
    },
  },
  computed: {
    timeSpent() {
      return sprintf(
        s__('TimeTracking|%{startTag}Spent: %{endTag}%{timeSpentHumanReadable}'),
        {
          startTag: '<span class="bold">',
          endTag: '</span>',
          timeSpentHumanReadable: this.timeSpentHumanReadable,
        },
        false,
      );
    },
  },
};
</script>

<template>
  <div class="time-tracking-spend-only-pane" v-html="timeSpent"></div>
</template>
