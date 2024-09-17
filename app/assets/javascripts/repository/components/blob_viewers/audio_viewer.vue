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
      src: this.blob.rawPath,
    };
  },
};
</script>
<template>
  <div class="gl-p-7 gl-text-center">
    <audio :src="src" controls data-testid="audio"></audio>
  </div>
</template>
