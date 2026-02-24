<script>
export default {
  name: 'ChildWithMultipleSlots',
};
</script>
<template>
  <div>
    <!-- eslint-disable-next-line vue/html-self-closing -->
    <slot name="header"></slot>
    <!-- eslint-disable-next-line vue/html-self-closing -->
    <slot></slot>
    <!-- eslint-disable-next-line vue/html-self-closing -->
    <slot name="footer"></slot>
  </div>
</template>
