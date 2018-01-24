<script>
  export default {
    props: {
      name: {
        type: String,
        required: true,
      },
    },
  };
</script>

<template>
  <div class="panel panel-default prometheus-panel">
    <div class="panel-heading">
      <h4>{{ name }}</h4>
    </div>
    <div class="panel-body prometheus-graph-group">
      <slot></slot>
    </div>
  </div>
</template>
