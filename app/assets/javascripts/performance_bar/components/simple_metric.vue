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
  computed: {
    duration() {
      return (
        this.currentRequest.details[this.metric] &&
        this.currentRequest.details[this.metric].duration
      );
    },
    calls() {
      return (
        this.currentRequest.details[this.metric] && this.currentRequest.details[this.metric].calls
      );
    },
  },
};
</script>
<template>
  <div :id="`peek-view-${metric}`" class="view">
    <span v-if="currentRequest.details" class="bold"> {{ duration }} / {{ calls }} </span>
    {{ metric }}
  </div>
</template>
