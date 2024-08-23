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
  <div class="gl-flex gl-break-anywhere">
    <span
      class="dropdown-label-box gl-top-0 gl-mr-3 gl-shrink-0"
      :style="{ 'background-color': label.color }"
      data-testid="label-color-box"
    ></span>
    <span>{{ label.title }}</span>
  </div>
</template>
