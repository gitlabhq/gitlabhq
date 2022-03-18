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
  <div class="gl-text-center gl-p-7">
    <audio :src="src" controls data-testid="audio"></audio>
  </div>
</template>
