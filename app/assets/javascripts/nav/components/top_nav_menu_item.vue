<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import { kebabCase, mapKeys } from 'lodash';

const getDataKey = (key) => `data-${kebabCase(key)}`;

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
  computed: {
    dataAttrs() {
      return mapKeys(this.menuItem.data || {}, (value, key) => getDataKey(key));
    },
  },
};
</script>

<template>
  <gl-button
    category="tertiary"
    :href="menuItem.href"
    class="top-nav-menu-item gl-display-block"
    :class="menuItem.css_class"
    v-bind="dataAttrs"
    v-on="$listeners"
  >
    <span class="gl-display-flex">
      <gl-icon v-if="menuItem.icon" :name="menuItem.icon" class="gl-mr-2!" />
      {{ menuItem.title }}
      <gl-icon v-if="menuItem.view" name="chevron-right" class="gl-ml-auto" />
    </span>
  </gl-button>
</template>
