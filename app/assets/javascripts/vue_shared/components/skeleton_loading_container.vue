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
      v-for="line in lines"
      :key="line"
      :class="'skeleton-line-' + line"
    >
    </div>
  </div>
</template>
