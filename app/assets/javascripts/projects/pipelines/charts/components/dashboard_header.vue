<script>
export default {
  name: 'DashboardHeader',
};
</script>
<template>
  <div>
    <h2 class="gl-heading-2 gl-mt-3">
      <slot></slot>
    </h2>
    <slot name="description"></slot>
  </div>
</template>
