<script>
import { GlCollapse } from '@gitlab/ui';
import { isCollapsed, toggleSuperSidebarCollapsed } from '../super_sidebar_collapsed_state_manager';
import UserBar from './user_bar.vue';
import SidebarPortalTarget from './sidebar_portal_target.vue';
import ContextSwitcherToggle from './context_switcher_toggle.vue';
import ContextSwitcher from './context_switcher.vue';
import HelpCenter from './help_center.vue';
import SidebarMenu from './sidebar_menu.vue';

export default {
  components: {
    GlCollapse,
    UserBar,
    ContextSwitcherToggle,
    ContextSwitcher,
    HelpCenter,
    SidebarMenu,
    SidebarPortalTarget,
  },
  props: {
    sidebarData: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      contextSwitcherOpened: false,
      isCollapased: isCollapsed(),
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
  },
};
</script>

<template>
  <div>
    <div class="super-sidebar-overlay" @click="collapseSidebar"></div>
    <aside
      id="super-sidebar"
      :aria-hidden="String(isCollapased)"
      class="super-sidebar"
      data-testid="super-sidebar"
      data-qa-selector="navbar"
      :inert="isCollapased"
      tabindex="-1"
    >
      <user-bar :sidebar-data="sidebarData" />
      <div class="gl-display-flex gl-flex-direction-column gl-flex-grow-1 gl-overflow-hidden">
        <div class="gl-flex-grow-1 gl-overflow-auto">
          <context-switcher-toggle
            :context="sidebarData.current_context_header"
            :expanded="contextSwitcherOpened"
          />
          <gl-collapse id="context-switcher" v-model="contextSwitcherOpened">
            <context-switcher
              :username="sidebarData.username"
              :projects-path="sidebarData.projects_path"
              :groups-path="sidebarData.groups_path"
              :current-context="sidebarData.current_context"
            />
          </gl-collapse>
          <gl-collapse :visible="!contextSwitcherOpened">
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
