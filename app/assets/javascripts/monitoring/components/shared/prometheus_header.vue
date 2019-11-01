<script>
export default {
  props: {
    graphTitle: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div class="prometheus-graph-header">
    <h5 class="prometheus-graph-title js-graph-title">{{ graphTitle }}</h5>
  </div>
</template>
