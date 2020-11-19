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
  <div data-testid="estimateOnlyPane">
    <span class="gl-font-weight-bold">{{ s__('TimeTracking|Estimated:') }} </span
    >{{ timeEstimateHumanReadable }}
  </div>
</template>
