<script>
import { GlButton, GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlIcon,
  },
  props: {
    menuItem: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <gl-button
    category="tertiary"
    :href="menuItem.href"
    class="top-nav-menu-item gl-display-block"
    v-on="$listeners"
  >
    <span class="gl-display-flex">
      <gl-icon v-if="menuItem.icon" :name="menuItem.icon" class="gl-mr-2!" />
      {{ menuItem.title }}
      <gl-icon v-if="menuItem.view" name="chevron-right" class="gl-ml-auto" />
    </span>
  </gl-button>
</template>
