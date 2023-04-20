<script>
import { GlButton, GlCollapse } from '@gitlab/ui';
import { __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  sidebarState,
  SUPER_SIDEBAR_PEEK_OPEN_DELAY,
  SUPER_SIDEBAR_PEEK_CLOSE_DELAY,
} from '../constants';
import { toggleSuperSidebarCollapsed } from '../super_sidebar_collapsed_state_manager';
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
  mixins: [glFeatureFlagsMixin()],
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
    return sidebarState;
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
    onHoverAreaMouseEnter() {
      this.openPeekTimer = setTimeout(this.openPeek, SUPER_SIDEBAR_PEEK_OPEN_DELAY);
    },
    onHoverAreaMouseLeave() {
      clearTimeout(this.openPeekTimer);
    },
    onSidebarMouseEnter() {
      clearTimeout(this.closePeekTimer);
    },
    onSidebarMouseLeave() {
      this.closePeekTimer = setTimeout(this.closePeek, SUPER_SIDEBAR_PEEK_CLOSE_DELAY);
    },
    closePeek() {
      if (this.isPeek) {
        this.isPeek = false;
        this.isCollapsed = true;
      }
    },
    openPeek() {
      this.isPeek = true;
      this.isCollapsed = false;

      // Cancel and start the timer to close sidebar, in case the user moves
      // the cursor fast enough away to not trigger a mouseenter event.
      // This is cancelled if the user moves the cursor into the sidebar.
      this.onSidebarMouseEnter();
      this.onSidebarMouseLeave();
    },
  },
};
</script>

<template>
  <div>
    <div class="super-sidebar-overlay" @click="collapseSidebar"></div>
    <div
      v-if="!isPeek && glFeatures.superSidebarPeek"
      class="super-sidebar-hover-area gl-fixed gl-left-0 gl-top-0 gl-bottom-0 gl-w-3"
      data-testid="super-sidebar-hover-area"
      @mouseenter="onHoverAreaMouseEnter"
      @mouseleave="onHoverAreaMouseLeave"
    ></div>
    <aside
      id="super-sidebar"
      class="super-sidebar"
      :class="{ 'super-sidebar-peek': isPeek }"
      data-testid="super-sidebar"
      data-qa-selector="navbar"
      :inert="isCollapsed"
      @mouseenter="onSidebarMouseEnter"
      @mouseleave="onSidebarMouseLeave"
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
        <context-switcher-toggle
          :context="sidebarData.current_context_header"
          :expanded="contextSwitcherOpen"
          data-qa-selector="context_switcher"
        />
        <div class="gl-flex-grow-1 gl-overflow-auto">
          <gl-collapse
            id="context-switcher"
            v-model="contextSwitcherOpen"
            data-qa-selector="context_section"
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
            <sidebar-menu
              :items="menuItems"
              :panel-type="sidebarData.panel_type"
              :pinned-item-ids="sidebarData.pinned_items"
              :update-pins-url="sidebarData.update_pins_url"
            />
            <sidebar-portal-target />
          </gl-collapse>
        </div>
        <div class="gl-p-3">
          <help-center :sidebar-data="sidebarData" />
        </div>
      </div>
    </aside>
    <a
      v-for="shortcutLink in sidebarData.shortcut_links"
      :key="shortcutLink.href"
      :href="shortcutLink.href"
      :class="shortcutLink.css_class"
      class="gl-display-none"
    >
      {{ shortcutLink.title }}
    </a>
  </div>
</template>
