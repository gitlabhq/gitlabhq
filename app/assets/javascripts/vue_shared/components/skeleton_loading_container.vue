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
        default: 3,
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
    :class="{
      'animation-container-small': small,
    }"
    class="animation-container"
  >
    <div
      v-for="(css, index) in lineClasses"
      :key="index"
      :class="css"
    >
    </div>
  </div>
</template>
