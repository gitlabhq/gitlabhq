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
    },
  };
</script>

<template>
  <div
    v-if="showPanels"
    class="panel panel-default prometheus-panel"
  >
    <div class="panel-heading">
      <h4>{{ name }}</h4>
    </div>
    <div class="panel-body prometheus-graph-group">
      <slot></slot>
    </div>
  </div>
  <div
    v-else
    class="prometheus-graph-group"
  >
    <slot></slot>
  </div>
</template>
