<script>
export default {
  props: {
    colors: {
      type: Array,
      required: true,
      validator(value) {
        return value.length === 2;
      },
    },
    opacity: {
      type: Array,
      required: true,
      validator(value) {
        return value.length === 2;
      },
    },
    identifierName: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <svg height="0" width="0">
    <defs>
      <linearGradient :id="identifierName">
        <stop :stop-color="colors[0]" :stop-opacity="opacity[0]" offset="0%" />
        <stop :stop-color="colors[1]" :stop-opacity="opacity[1]" offset="100%" />
      </linearGradient>
    </defs>
  </svg>
</template>
