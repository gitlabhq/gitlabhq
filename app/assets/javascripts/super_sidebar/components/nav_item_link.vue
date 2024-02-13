<script>
import { NAV_ITEM_LINK_ACTIVE_CLASS } from '../constants';
import { ariaCurrent } from '../utils';

export default {
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isActive() {
      return this.item.is_active;
    },
    linkProps() {
      return {
        href: this.item.link,
        'aria-current': ariaCurrent(this.isActive),
      };
    },
    computedLinkClasses() {
      return {
        [NAV_ITEM_LINK_ACTIVE_CLASS]: this.isActive,
      };
    },
  },
};
</script>

<template>
  <a v-bind="linkProps" :class="computedLinkClasses" @click="$emit('nav-link-click')">
    <slot :is-active="isActive"></slot>
  </a>
</template>
