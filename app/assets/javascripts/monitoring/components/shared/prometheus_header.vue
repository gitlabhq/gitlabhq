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
    <h5 ref="title" class="prometheus-graph-title">{{ graphTitle }}</h5>
  </div>
</template>
