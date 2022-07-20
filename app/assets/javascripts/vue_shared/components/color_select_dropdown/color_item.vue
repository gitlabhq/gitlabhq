<script>
export default {
  props: {
    color: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="color-item">
    <span
      class="dropdown-label-box color-item-color"
      data-testid="color-item"
      :style="{ backgroundColor: color }"
    ></span>
    <span class="color-item-text">{{ title }}</span>
  </div>
</template>
