<script>
export default {
  props: {
    label: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div class="gl-my-5 gl-display-flex">
    <div class="gl-font-weight-bold gl-w-13 gl-text-right gl-pr-3">{{ label }}</div>
    <div class="gl-pl-2">
      <slot></slot>
    </div>
  </div>
</template>
