<script>
import { GlButton } from '@gitlab/ui';
import Mousetrap from 'mousetrap';
import { keysFor, TOGGLE_SUPER_SIDEBAR } from '~/behaviors/shortcuts/keybindings';
import { __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  sidebarState,
  SUPER_SIDEBAR_PEEK_OPEN_DELAY,
  SUPER_SIDEBAR_PEEK_CLOSE_DELAY,
} from '../constants';
import { isCollapsed, toggleSuperSidebarCollapsed } from '../super_sidebar_collapsed_state_manager';
import UserBar from './user_bar.vue';
import SidebarPortalTarget from './sidebar_portal_target.vue';
import ContextSwitcher from './context_switcher.vue';
import HelpCenter from './help_center.vue';
import SidebarMenu from './sidebar_menu.vue';

export default {
  components: {
    GlButton,
    UserBar,
    ContextSwitcher,
    HelpCenter,
    SidebarMenu,
    SidebarPortalTarget,
    TrialStatusWidget: () =>
      import('ee_component/contextual_sidebar/components/trial_status_widget.vue'),
    TrialStatusPopover: () =>
      import('ee_component/contextual_sidebar/components/trial_status_popover.vue'),
  },
  mixins: [glFeatureFlagsMixin()],
  i18n: {
    skipToMainContent: __('Skip to main content'),
  },
  inject: ['showTrialStatusWidget'],
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
  watch: {
    isCollapsed() {
      if (this.isCollapsed) {
        this.$refs['context-switcher'].close();
      }
    },
  },
  mounted() {
    Mousetrap.bind(keysFor(TOGGLE_SUPER_SIDEBAR), this.toggleSidebar);
  },
  beforeDestroy() {
    Mousetrap.unbind(keysFor(TOGGLE_SUPER_SIDEBAR));
  },
  methods: {
    toggleSidebar() {
      toggleSuperSidebarCollapsed(!isCollapsed(), true);
    },
    collapseSidebar() {
      toggleSuperSidebarCollapsed(true, false);
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
    onContextSwitcherToggled(open) {
      this.contextSwitcherOpen = open;
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
      <div v-if="showTrialStatusWidget" class="gl-px-2 gl-py-2">
        <trial-status-widget
          class="gl-rounded-base gl-relative gl-display-flex gl-align-items-center gl-mb-1 gl-px-3 gl-line-height-normal gl-text-black-normal! gl-hover-bg-t-gray-a-08 gl-focus-bg-t-gray-a-08 gl-text-decoration-none! nav-item-link gl-py-3"
        />
        <trial-status-popover />
      </div>
      <div class="gl-display-flex gl-flex-direction-column gl-flex-grow-1 gl-overflow-hidden">
        <div
          class="gl-flex-grow-1"
          :class="{ 'gl-overflow-auto': !contextSwitcherOpen }"
          data-testid="nav-container"
        >
          <context-switcher
            ref="context-switcher"
            :persistent-links="sidebarData.context_switcher_links"
            :username="sidebarData.username"
            :projects-path="sidebarData.projects_path"
            :groups-path="sidebarData.groups_path"
            :current-context="sidebarData.current_context"
            :context-header="sidebarData.current_context_header"
            @toggle="onContextSwitcherToggled"
          />
          <sidebar-menu
            :items="menuItems"
            :panel-type="sidebarData.panel_type"
            :pinned-item-ids="sidebarData.pinned_items"
            :update-pins-url="sidebarData.update_pins_url"
          />
          <sidebar-portal-target />
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
