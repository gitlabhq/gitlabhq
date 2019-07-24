<script>
export default {
  props: {
    name: {
      type: String,
      required: true,
    },
    showPanels: {
      type: Boolean,
      required: false,
      default: true,
    },
    collapseGroup: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <div v-if="showPanels" class="card prometheus-panel">
    <div class="card-header">
      <h4>{{ name }}</h4>
    </div>
    <div v-if="collapseGroup" class="card-body prometheus-graph-group"><slot></slot></div>
  </div>
  <div v-else class="prometheus-graph-group"><slot></slot></div>
</template>
