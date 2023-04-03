<script>
import { GlButton, GlCollapse } from '@gitlab/ui';
import { __ } from '~/locale';
import { isCollapsed, toggleSuperSidebarCollapsed } from '../super_sidebar_collapsed_state_manager';
import { SUPER_SIDEBAR_PEEK_DELAY } from '../constants';
import UserBar from './user_bar.vue';
import SidebarPortalTarget from './sidebar_portal_target.vue';
import ContextSwitcherToggle from './context_switcher_toggle.vue';
import ContextSwitcher from './context_switcher.vue';
import HelpCenter from './help_center.vue';
import SidebarMenu from './sidebar_menu.vue';

export default {
  components: {
    GlButton,
    GlCollapse,
    UserBar,
    ContextSwitcherToggle,
    ContextSwitcher,
    HelpCenter,
    SidebarMenu,
    SidebarPortalTarget,
  },
  i18n: {
    skipToMainContent: __('Skip to main content'),
  },
  props: {
    sidebarData: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      contextSwitcherOpen: false,
      isInert: isCollapsed(),
      isPeek: false,
    };
  },
  computed: {
    menuItems() {
      return this.sidebarData.current_menu_items || [];
    },
  },
  methods: {
    collapseSidebar() {
      toggleSuperSidebarCollapsed(true, false);
    },
    onContextSwitcherShown() {
      this.$refs['context-switcher'].focusInput();
    },
    onMouseOver() {
      setTimeout(() => {
        this.isPeek = true;
        this.isInert = false;
      }, SUPER_SIDEBAR_PEEK_DELAY);
    },
    onMouseLeave() {
      setTimeout(() => {
        this.isPeek = false;
        this.isInert = true;
      }, SUPER_SIDEBAR_PEEK_DELAY);
    },
  },
};
</script>

<template>
  <div>
    <div class="super-sidebar-overlay" @click="collapseSidebar"></div>
    <div
      v-if="!isPeek"
      class="super-sidebar-hover-area gl-fixed gl-left-0 gl-top-0 gl-bottom-0 gl-w-3"
      data-testid="super-sidebar-hover-area"
      @mouseover="onMouseOver"
    ></div>
    <aside
      id="super-sidebar"
      class="super-sidebar"
      :class="{ 'gl-visibility-hidden': isInert, 'super-sidebar-peek': isPeek }"
      data-testid="super-sidebar"
      data-qa-selector="navbar"
      :inert="isInert"
      tabindex="-1"
      @mouseleave="onMouseLeave"
    >
      <gl-button
        class="super-sidebar-skip-to gl-sr-only-focusable gl-absolute gl-left-3 gl-right-3 gl-top-3"
        href="#content-body"
        variant="confirm"
      >
        {{ $options.i18n.skipToMainContent }}
      </gl-button>
      <user-bar :has-collapse-button="!isPeek" :sidebar-data="sidebarData" />
      <div class="gl-display-flex gl-flex-direction-column gl-flex-grow-1 gl-overflow-hidden">
        <div class="gl-flex-grow-1 gl-overflow-auto">
          <context-switcher-toggle
            :context="sidebarData.current_context_header"
            :expanded="contextSwitcherOpen"
          />
          <gl-collapse
            id="context-switcher"
            v-model="contextSwitcherOpen"
            @shown="onContextSwitcherShown"
          >
            <context-switcher
              ref="context-switcher"
              :persistent-links="sidebarData.context_switcher_links"
              :username="sidebarData.username"
              :projects-path="sidebarData.projects_path"
              :groups-path="sidebarData.groups_path"
              :current-context="sidebarData.current_context"
            />
          </gl-collapse>
          <gl-collapse :visible="!contextSwitcherOpen">
            <sidebar-menu :items="menuItems" />
            <sidebar-portal-target />
          </gl-collapse>
        </div>
        <div class="gl-p-3">
          <help-center :sidebar-data="sidebarData" />
        </div>
      </div>
    </aside>
  </div>
</template>
