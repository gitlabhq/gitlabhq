<script>
export default {
  name: 'TimeTrackingEstimateOnlyPane',
  props: {
    timeEstimateHumanReadable: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="time-tracking-estimate-only-pane">
    <span class="bold">
      {{ s__('TimeTracking|Estimated:') }}
    </span>
    {{ timeEstimateHumanReadable }}
  </div>
</template>
