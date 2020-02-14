<script>
export default {
  props: {
    viewerError: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div class="file-content code">
    <div class="text-center py-4" v-html="viewerError"></div>
  </div>
</template>
