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
      <h4>{{name}}</h4>
    </div>
    <div class="panel-body">
      <slot />
    </div>
  </div>
</template>
