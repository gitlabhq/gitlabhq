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
  <div class="gl-display-flex gl-flex-direction-column gl-sm-flex-direction-row gl-mb-4">
    <p class="gl-font-bold gl-flex-grow-1 gl-flex-basis-0 gl-mb-0">
      {{ label }}
    </p>
    <div class="gl-flex-grow-1 gl-flex-basis-two-thirds">
      <slot>{{ value }}</slot>
    </div>
  </div>
</template>
