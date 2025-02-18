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
      url: this.blob.externalStorageUrl || this.blob.rawPath,
      alt: this.blob.name,
    };
  },
};
</script>
<template>
  <div class="gl-bg-strong gl-p-7 gl-text-center">
    <img :src="url" :alt="alt" data-testid="image" class="gl-max-w-full" />
  </div>
</template>
