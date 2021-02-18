<script>
import { GlDropdownItem } from '@gitlab/ui';

export default {
  components: {
    GlDropdownItem,
  },
  props: {
    path: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <gl-dropdown-item :href="path" data-method="delete">
    <slot></slot>
  </gl-dropdown-item>
</template>
