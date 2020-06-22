<script>
export default {
  name: 'ListItem',
  props: {
    index: {
      type: Number,
      default: 0,
      required: false,
    },
    disabled: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  computed: {
    optionalClasses() {
      return {
        'gl-border-t-solid gl-border-t-1': this.index === 0,
        'disabled-content': this.disabled,
      };
    },
  },
};
</script>

<template>
  <div
    :class="[
      'gl-display-flex gl-justify-content-space-between gl-align-items-center gl-py-2 gl-px-1 gl-border-gray-200 gl-border-b-solid gl-border-b-1 gl-py-4',
      optionalClasses,
    ]"
  >
    <div class="gl-display-flex gl-flex-direction-column">
      <div class="gl-display-flex gl-align-items-center">
        <slot name="left-primary"></slot>
      </div>
      <div class="gl-font-sm gl-text-gray-500">
        <slot name="left-secondary"></slot>
      </div>
    </div>

    <div>
      <slot name="right"></slot>
    </div>
  </div>
</template>
