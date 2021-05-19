<script>
import { GlNav, GlNavItemDropdown, GlDropdownForm, GlTooltip } from '@gitlab/ui';
import { s__ } from '~/locale';
import TopNavDropdownMenu from './top_nav_dropdown_menu.vue';

const TOOLTIP = s__('TopNav|Switch to...');

export default {
  components: {
    GlNav,
    GlNavItemDropdown,
    GlDropdownForm,
    GlTooltip,
    TopNavDropdownMenu,
  },
  props: {
    navData: {
      type: Object,
      required: true,
    },
  },
  methods: {
    findTooltipTarget() {
      // ### Why use a target function instead of `v-gl-tooltip`?
      // To get the tooltip to align correctly, we need it to target the actual
      // toggle button which we don't directly render.
      return this.$el.querySelector('.js-top-nav-dropdown-toggle');
    },
  },
  TOOLTIP,
};
</script>

<template>
  <gl-nav class="navbar-sub-nav">
    <gl-nav-item-dropdown
      :text="navData.activeTitle"
      icon="dot-grid"
      menu-class="gl-mt-3! gl-max-w-none! gl-max-h-none! gl-sm-w-auto!"
      toggle-class="top-nav-toggle js-top-nav-dropdown-toggle gl-px-3!"
      no-flip
    >
      <gl-dropdown-form>
        <top-nav-dropdown-menu
          :primary="navData.primary"
          :secondary="navData.secondary"
          :views="navData.views"
        />
      </gl-dropdown-form>
    </gl-nav-item-dropdown>
    <gl-tooltip
      boundary="window"
      :boundary-padding="0"
      :target="findTooltipTarget"
      placement="right"
      :title="$options.TOOLTIP"
    />
  </gl-nav>
</template>
