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
  <div>{{ job.id }}</div>
</template>
