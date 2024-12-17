<script>
export default {};
</script>
<template>
  <div class="gl-flex gl-flex-col">
    <span class="gl-mb-2 gl-font-bold gl-text-heading">
      <slot name="header"></slot>
    </span>
    <slot></slot>
  </div>
</template>
