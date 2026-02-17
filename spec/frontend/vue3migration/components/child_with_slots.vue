<script>
export default {
  name: 'ChildWithSlots',
};
</script>
<template>
  <div class="wrapper">
    <!-- eslint-disable-next-line vue/html-self-closing -->
    <slot name="named" />
    <!-- eslint-disable-next-line vue/html-self-closing -->
    <slot />
  </div>
</template>
