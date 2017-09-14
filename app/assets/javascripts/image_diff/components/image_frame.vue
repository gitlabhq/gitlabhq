<script>
  export default {
    name: 'imageFrame',
    props: {
      src: {
        type: String,
        required: true,
      },
      alt: {
        type: String,
        required: true,
      },
      className: {
        type: String,
        required: false,
      },
    },
    methods: {
      load(event) {
        this.$emit('imageLoaded', event);
      },
    },
  };
</script>

<template>
  <div
    class="frame"
    :class="className"
  >
    <img
      @load="load"
      :src="src"
      :alt="alt"
    />
  </div>
</template>
