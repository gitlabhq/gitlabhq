<script>
export default {
  props: {
    job: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <div class="container-fluid gl-grid-tpl-rows-auto">
    {{ job.name }}
  </div>
</template>
