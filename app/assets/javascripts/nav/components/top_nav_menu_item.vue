<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import { kebabCase, mapKeys } from 'lodash';

const getDataKey = (key) => `data-${kebabCase(key)}`;

const ACTIVE_CLASS = 'gl-shadow-none! gl-font-weight-bold! active';

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
    iconOnly: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    dataAttrs() {
      return mapKeys(this.menuItem.data || {}, (value, key) => getDataKey(key));
    },
  },
  ACTIVE_CLASS,
};
</script>

<template>
  <gl-button
    category="tertiary"
    :href="menuItem.href"
    class="top-nav-menu-item gl-display-block"
    :class="[menuItem.css_class, { [$options.ACTIVE_CLASS]: menuItem.active }]"
    :aria-label="menuItem.title"
    v-bind="dataAttrs"
    v-on="$listeners"
  >
    <span class="gl-display-flex">
      <gl-icon v-if="menuItem.icon" :name="menuItem.icon" :class="{ 'gl-mr-3!': !iconOnly }" />
      <template v-if="!iconOnly">
        {{ menuItem.title }}
        <gl-icon v-if="menuItem.view" name="chevron-right" class="gl-ml-auto" />
      </template>
    </span>
  </gl-button>
</template>
