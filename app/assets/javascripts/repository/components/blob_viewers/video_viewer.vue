<script>
export default {
  props: {
    blob: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      url: this.blob.rawPath,
    };
  },
};
</script>
<template>
  <div class="gl-text-center gl-p-7 gl-bg-gray-50">
    <video :src="url" controls data-testid="video" class="gl-max-w-full"></video>
  </div>
</template>
