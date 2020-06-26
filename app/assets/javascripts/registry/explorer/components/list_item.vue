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
    selected: {
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
        'gl-border-gray-200': !this.selected,
        'gl-bg-blue-50 gl-border-blue-200': this.selected,
      };
    },
  },
};
</script>

<template>
  <div
    class="gl-display-flex gl-align-items-center gl-border-b-solid gl-border-b-1 gl-py-4 gl-px-2"
    :class="optionalClasses"
  >
    <div v-if="$slots['left-action']" class="gl-mr-5 gl-display-none gl-display-sm-block">
      <slot name="left-action"></slot>
    </div>
    <div class="gl-display-flex gl-flex-direction-column gl-flex-fill-1">
      <div
        class="gl-display-flex gl-align-items-center gl-justify-content-space-between gl-text-black-normal gl-font-weight-bold"
      >
        <div>
          <slot name="left-primary"></slot>
        </div>
        <div>
          <slot name="right-primary"></slot>
        </div>
      </div>
      <div
        class="gl-display-flex gl-align-items-center gl-justify-content-space-between gl-font-sm gl-text-gray-500"
      >
        <div>
          <slot name="left-secondary"></slot>
        </div>
        <div>
          <slot name="right-secondary"></slot>
        </div>
      </div>
    </div>
    <div v-if="$slots['right-action']" class="gl-ml-5 gl-display-none gl-display-sm-block">
      <slot name="right-action"></slot>
    </div>
  </div>
</template>
