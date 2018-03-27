<script>
  export default {
    props: {
      small: {
        type: Boolean,
        required: false,
        default: false,
      },
      lines: {
        type: Number,
        required: false,
        default: 6,
      },
    },
    computed: {
      lineClasses() {
        return new Array(this.lines).fill().map((_, i) => `skeleton-line-${i + 1}`);
      },
    },
  };
</script>

<template>
  <div
    class="animation-container"
    :class="{
      'animation-container-small': small,
    }"
  >
    <div
      v-for="(css, index) in lineClasses"
      :key="index"
      :class="css"
    >
    </div>
  </div>
</template>
