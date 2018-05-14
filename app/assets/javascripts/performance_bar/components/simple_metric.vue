<script>
export default {
  props: {
    currentRequest: {
      type: Object,
      required: true,
    },
    metric: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div
    :id="`peek-view-${metric}`"
    class="view"
  >
    <span
      v-if="currentRequest.details"
      class="bold"
    >
      {{ currentRequest.details[metric].duration }}
      /
      {{ currentRequest.details[metric].calls }}
    </span>
    {{ metric }}
  </div>
</template>
