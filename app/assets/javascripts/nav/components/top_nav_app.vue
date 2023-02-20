<script>
import { GlNav, GlIcon, GlNavItemDropdown, GlDropdownForm, GlTooltipDirective } from '@gitlab/ui';
import Tracking from '~/tracking';
import TopNavDropdownMenu from './top_nav_dropdown_menu.vue';

export default {
  components: {
    GlIcon,
    GlNav,
    GlNavItemDropdown,
    GlDropdownForm,
    TopNavDropdownMenu,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    navData: {
      type: Object,
      required: true,
    },
  },
  methods: {
    trackToggleEvent() {
      Tracking.event(undefined, 'click_nav', {
        label: 'hamburger_menu',
        property: 'navigation_top',
      });
    },
  },
};
</script>

<template>
  <gl-nav class="navbar-sub-nav">
    <gl-nav-item-dropdown
      v-gl-tooltip.bottom="navData.menuTooltip"
      data-qa-selector="navbar_dropdown"
      data-qa-title="Menu"
      menu-class="gl-mt-3! gl-max-w-none! gl-max-h-none! gl-sm-w-auto! js-top-nav-dropdown-menu"
      toggle-class="top-nav-toggle js-top-nav-dropdown-toggle gl-px-3!"
      no-flip
      no-caret
      @toggle="trackToggleEvent"
    >
      <template #button-content>
        <gl-icon name="hamburger" />
        <span v-if="navData.menuTitle" class="gl-ml-3">
          {{ navData.menuTitle }}
        </span>
      </template>
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
