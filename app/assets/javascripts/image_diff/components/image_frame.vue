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
      click() {
        this.$emit('click', event);
      },
    },
  };
</script>

<template>
  <div
    class="frame click-to-comment"
    :class="className"
  >
    <img
      @click="click"
      @load="load"
      :src="src"
      :alt="alt"
    />
    <slot />
  </div>
</template>
