<script>
import { GlTooltipDirective } from '@gitlab/ui';
import TopNavMenuItem from './top_nav_menu_item.vue';

export default {
  components: {
    TopNavMenuItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  computed: {
    menuItem() {
      return {
        id: 'home',
        view: 'home',
        icon: 'angle-left',
      };
    },
  },
};
</script>

<template>
  <header class="gl-py-4 gl-display-flex gl-align-items-center">
    <top-nav-menu-item
      v-gl-tooltip="{ title: s__('TopNav|Go back') }"
      class="gl-p-3!"
      :menu-item="menuItem"
      icon-only
      @click="$emit('menu-item-click', menuItem)"
    />
    <span class="gl-font-size-h2 gl-font-weight-bold gl-ml-2">
      <slot></slot>
    </span>
  </header>
</template>
