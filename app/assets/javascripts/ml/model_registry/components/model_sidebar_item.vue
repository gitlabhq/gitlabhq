<script>
export default {
  props: {
    title: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <div class="gl-border-t gl-flex gl-flex-col gl-gap-2 gl-border-t-subtle gl-pt-5">
    <h3 class="gl-heading-5 gl-mb-0">
      {{ title }}
    </h3>
    <div class="gl-text-subtle">
      <slot></slot>
    </div>
  </div>
</template>
