<script>
export default {};
</script>
<template>
  <div class="gl-display-flex gl-flex-direction-column">
    <span class="gl-text-gray-900 gl-font-weight-bold gl-mb-2">
      <slot name="header"></slot>
    </span>
    <slot></slot>
  </div>
</template>
