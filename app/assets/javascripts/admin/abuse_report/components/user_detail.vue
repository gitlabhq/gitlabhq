<script>
export default {
  name: 'UserDetail',
  props: {
    label: {
      type: String,
      required: true,
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
  <div class="gl-mb-4 gl-flex gl-flex-col sm:gl-flex-row">
    <p class="gl-mb-0 gl-grow gl-basis-0 gl-font-bold">
      {{ label }}
    </p>
    <div class="gl-grow gl-basis-2/3">
      <slot>{{ value }}</slot>
    </div>
  </div>
</template>
