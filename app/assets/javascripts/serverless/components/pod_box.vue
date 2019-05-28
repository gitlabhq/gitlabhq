<script>
export default {
  props: {
    count: {
      type: Number,
      required: true,
    },
    color: {
      type: String,
      required: false,
      default: 'green',
    },
  },
  methods: {
    boxOffset(i) {
      return 20 * (i - 1);
    },
  },
};
</script>

<template>
  <svg :width="boxOffset(count + 1)" :height="20">
    <rect
      v-for="i in count"
      :key="i"
      width="15"
      height="15"
      rx="5"
      ry="5"
      :fill="color"
      :x="boxOffset(i)"
      y="0"
    />
  </svg>
</template>
