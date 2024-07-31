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
  <div class="gl-my-5 gl-flex">
    <div class="gl-w-13 gl-pr-3 gl-text-right gl-font-bold">{{ label }}</div>
    <div class="gl-pl-2">
      <slot></slot>
    </div>
  </div>
</template>
