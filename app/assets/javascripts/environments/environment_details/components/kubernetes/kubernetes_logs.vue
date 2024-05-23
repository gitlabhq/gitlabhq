<script>
export default {
  props: {
    podName: {
      type: String,
      required: true,
    },
    namespace: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div>{{ podName }} {{ namespace }}</div>
</template>
