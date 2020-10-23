<script>
/* eslint-disable vue/no-v-html */
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
          startTag: '<span class="gl-font-weight-bold">',
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
  <div data-testid="spentOnlyPane" v-html="timeSpent"></div>
</template>
