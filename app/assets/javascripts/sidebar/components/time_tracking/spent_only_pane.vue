<script>
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

const timeSpent = s__('TimeTracking|%{spentStart}Spent: %{spentEnd}');

export default {
  name: 'TimeTrackingSpentOnlyPane',
  timeSpent,
  components: {
    GlSprintf,
  },
  props: {
    timeSpentHumanReadable: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div data-testid="spentOnlyPane">
    <gl-sprintf :message="$options.timeSpent">
      <template #spent="{ content }">
        <span class="gl-font-bold">{{ content }}</span
        >{{ timeSpentHumanReadable }}
      </template>
    </gl-sprintf>
  </div>
</template>
