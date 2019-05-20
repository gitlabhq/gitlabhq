<script>
export default {
  props: {
    path: {
      type: String,
      required: false,
      default: '/',
    },
  },
};
</script>

<template>
  <div>{{ path }}</div>
</template>
