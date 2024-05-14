<script>
export default {
  props: {
    label: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-break-anywhere">
    <span
      class="dropdown-label-box gl-flex-shrink-0 gl-top-0 gl-mr-3"
      :style="{ 'background-color': label.color }"
      data-testid="label-color-box"
    ></span>
    <span>{{ label.title }}</span>
  </div>
</template>
