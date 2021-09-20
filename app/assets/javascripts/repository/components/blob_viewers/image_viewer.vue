<script>
export default {
  props: {
    url: {
      type: String,
      required: true,
    },
    alt: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div class="gl-text-center gl-p-7 gl-bg-gray-50">
    <img :src="url" :alt="alt" data-testid="image" />
  </div>
</template>
