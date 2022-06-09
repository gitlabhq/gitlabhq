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
  <div>
    <span
      class="dropdown-label-box gl-flex-shrink-0 gl-top-1 gl-mr-0"
      data-testid="color-item"
      :style="{ backgroundColor: color }"
    ></span>
    <span class="hide-collapsed">{{ title }}</span>
  </div>
</template>
