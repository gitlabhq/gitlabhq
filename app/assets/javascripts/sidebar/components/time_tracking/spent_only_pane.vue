<script>
export default {
  name: 'TimeTrackingSpentOnlyPane',
  props: {
    timeSpentHumanReadable: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="time-tracking-spend-only-pane">
    <span class="bold">Spent:</span>
    {{ timeSpentHumanReadable }}
  </div>
</template>
