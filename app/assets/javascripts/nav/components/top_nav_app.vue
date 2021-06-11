<script>
import { GlNav, GlNavItemDropdown, GlDropdownForm } from '@gitlab/ui';
import TopNavDropdownMenu from './top_nav_dropdown_menu.vue';

export default {
  components: {
    GlNav,
    GlNavItemDropdown,
    GlDropdownForm,
    TopNavDropdownMenu,
  },
  props: {
    navData: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <gl-nav class="navbar-sub-nav">
    <gl-nav-item-dropdown
      :text="navData.activeTitle"
      data-qa-selector="navbar_dropdown"
      :data-qa-title="navData.activeTitle"
      icon="hamburger"
      menu-class="gl-mt-3! gl-max-w-none! gl-max-h-none! gl-sm-w-auto! js-top-nav-dropdown-menu"
      toggle-class="top-nav-toggle js-top-nav-dropdown-toggle gl-px-3!"
      no-flip
      no-caret
    >
      <gl-dropdown-form>
        <top-nav-dropdown-menu
          :primary="navData.primary"
          :secondary="navData.secondary"
          :views="navData.views"
        />
      </gl-dropdown-form>
    </gl-nav-item-dropdown>
  </gl-nav>
</template>
