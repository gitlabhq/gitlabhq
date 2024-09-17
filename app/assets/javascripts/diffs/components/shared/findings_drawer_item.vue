<script>
export default {
  props: {
    description: {
      type: String,
      required: false,
      default: '',
    },
    value: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>
<template>
  <li class="gl-mb-4">
    <p class="gl-leading-20">
      <span data-testid="findings-drawer-item-description" class="gl-mb-1 gl-block gl-font-bold">{{
        description
      }}</span>
      <slot name="value">
        <span data-testid="findings-drawer-item-value-prop">{{ value }}</span>
      </slot>
    </p>
  </li>
</template>
