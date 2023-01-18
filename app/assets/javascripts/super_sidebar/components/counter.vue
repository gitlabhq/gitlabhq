<script>
import { GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
  },
  props: {
    count: {
      type: Number,
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
    class="counter gl-relative gl-display-inline-block gl-flex-grow-1 gl-text-center gl-py-3 gl-bg-gray-10 gl-rounded-base gl-text-black-normal gl-border gl-border-gray-a-08 gl-font-sm gl-font-weight-bold"
  >
    <gl-icon aria-hidden="true" :name="icon" />
    <span aria-hidden="true">{{ count }}</span>
  </component>
</template>
