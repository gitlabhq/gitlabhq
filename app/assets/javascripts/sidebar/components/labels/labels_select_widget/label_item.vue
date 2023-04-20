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
  <div class="gl-display-flex gl-align-items-center gl-word-break-word gl-relative gl-pl-4">
    <span
      class="dropdown-label-box gl-flex-shrink-0 gl-top-0 gl-absolute"
      :style="{ 'background-color': label.color }"
      data-testid="label-color-box"
    ></span>
    <span>{{ label.title }}</span>
  </div>
</template>
