<script>
import { GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
  },
  props: {
    count: {
      type: [Number, String],
      required: true,
    },
    href: {
      type: String,
      required: false,
      default: '',
    },
    icon: {
      type: String,
      required: true,
    },
    label: {
      type: String,
      required: true,
    },
  },
  computed: {
    ariaLabel() {
      return `${this.label} ${this.count}`;
    },
    component() {
      return this.href ? 'a' : 'button';
    },
  },
};
</script>

<template>
  <component
    :is="component"
    :aria-label="ariaLabel"
    :href="href"
    class="counter gl-display-block gl-flex-grow-1 gl-text-center gl-py-3 gl-bg-gray-10 gl-rounded-base gl-text-gray-900 gl-border-none gl-inset-border-1-gray-a-08 gl-line-height-1 gl-font-sm gl-hover-text-gray-900 gl-hover-text-decoration-none gl-focus--focus"
  >
    <gl-icon aria-hidden="true" :name="icon" />
    <span v-if="count" aria-hidden="true" class="gl-ml-1">{{ count }}</span>
  </component>
</template>
