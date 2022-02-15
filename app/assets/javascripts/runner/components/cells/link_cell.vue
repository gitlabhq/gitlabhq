<script>
import { GlLink } from '@gitlab/ui';

export default {
  props: {
    href: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    component() {
      if (this.href) {
        return GlLink;
      }
      return 'span';
    },
  },
};
</script>

<template>
  <component :is="component" :href="href" v-bind="$attrs" v-on="$listeners">
    <slot></slot>
  </component>
</template>
