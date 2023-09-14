<script>
import { GlButton } from '@gitlab/ui';
import { Mousetrap } from '~/lib/mousetrap';
import { keysFor, TOGGLE_SUPER_SIDEBAR } from '~/behaviors/shortcuts/keybindings';
import { __, s__ } from '~/locale';
import Tracking from '~/tracking';
import {
  sidebarState,
  SUPER_SIDEBAR_PEEK_STATE_CLOSED as STATE_CLOSED,
  SUPER_SIDEBAR_PEEK_STATE_WILL_OPEN as STATE_WILL_OPEN,
  SUPER_SIDEBAR_PEEK_STATE_OPEN as STATE_OPEN,
} from '../constants';
import { isCollapsed, toggleSuperSidebarCollapsed } from '../super_sidebar_collapsed_state_manager';
import { trackContextAccess } from '../utils';
import UserBar from './user_bar.vue';
import SidebarPortalTarget from './sidebar_portal_target.vue';
import HelpCenter from './help_center.vue';
import SidebarMenu from './sidebar_menu.vue';
import SidebarPeekBehavior from './sidebar_peek_behavior.vue';
import SidebarHoverPeekBehavior from './sidebar_hover_peek_behavior.vue';

export default {
  components: {
    GlButton,
    UserBar,
    HelpCenter,
    SidebarMenu,
    SidebarPeekBehavior,
    SidebarHoverPeekBehavior,
    SidebarPortalTarget,
    TrialStatusWidget: () =>
      import('ee_component/contextual_sidebar/components/trial_status_widget.vue'),
    TrialStatusPopover: () =>
      import('ee_component/contextual_sidebar/components/trial_status_popover.vue'),
  },
  mixins: [Tracking.mixin()],
  i18n: {
    skipToMainContent: __('Skip to main content'),
    primary: s__('Navigation|Primary'),
  },
  inject: ['showTrialStatusWidget'],
  props: {
    sidebarData: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      sidebarState,
      showPeekHint: false,
      isMouseover: false,
      breakpoint: null,
    };
  },
  computed: {
    showOverlay() {
      return this.sidebarState.isPeek || this.sidebarState.isHoverPeek;
    },
    menuItems() {
      return this.sidebarData.current_menu_items || [];
    },
    peekClasses() {
      return {
        'super-sidebar-peek-hint': this.showPeekHint,
        'super-sidebar-peek': this.showOverlay,
        'super-sidebar-has-peeked': this.sidebarState.hasPeeked,
      };
    },
  },
  created() {
    const {
      is_logged_in: isLoggedIn,
      current_context: currentContext,
      username,
      track_visits_path: trackVisitsPath,
    } = this.sidebarData;
    if (isLoggedIn && currentContext.namespace) {
      trackContextAccess(username, currentContext, trackVisitsPath);
    }
  },
  mounted() {
    Mousetrap.bind(keysFor(TOGGLE_SUPER_SIDEBAR), this.toggleSidebar);
  },
  beforeDestroy() {
    Mousetrap.unbind(keysFor(TOGGLE_SUPER_SIDEBAR));
  },
  methods: {
    toggleSidebar() {
      this.track(isCollapsed() ? 'nav_show' : 'nav_hide', {
        label: 'nav_toggle_keyboard_shortcut',
        property: 'nav_sidebar',
      });
      toggleSuperSidebarCollapsed(!isCollapsed(), true);
    },
    collapseSidebar() {
      toggleSuperSidebarCollapsed(true, false);
    },
    onPeekChange(state) {
      if (state === STATE_CLOSED) {
        this.sidebarState.isPeek = false;
        this.sidebarState.isCollapsed = true;
        this.showPeekHint = false;
      } else if (state === STATE_WILL_OPEN) {
        this.sidebarState.hasPeeked = true;
        this.sidebarState.isPeek = false;
        this.sidebarState.isCollapsed = true;
        this.showPeekHint = true;
      } else {
        this.sidebarState.isPeek = true;
        this.sidebarState.isCollapsed = false;
        this.showPeekHint = false;
      }
    },
    onHoverPeekChange(state) {
      if (state === STATE_OPEN) {
        this.sidebarState.hasPeeked = true;
        this.sidebarState.isHoverPeek = true;
        this.sidebarState.isCollapsed = false;
      } else if (state === STATE_CLOSED) {
        this.sidebarState.isHoverPeek = false;
        this.sidebarState.isCollapsed = true;
      }
    },
  },
};
</script>

<template>
  <div>
    <div class="super-sidebar-overlay" @click="collapseSidebar"></div>
    <gl-button
      class="super-sidebar-skip-to gl-sr-only-focusable gl-fixed gl-left-0 gl-m-3"
      href="#content-body"
      variant="confirm"
    >
      {{ $options.i18n.skipToMainContent }}
    </gl-button>
    <nav
      id="super-sidebar"
      :aria-label="$options.i18n.primary"
      class="super-sidebar"
      :class="peekClasses"
      data-testid="super-sidebar"
      data-qa-selector="navbar"
      :inert="sidebarState.isCollapsed"
      @mouseenter="isMouseover = true"
      @mouseleave="isMouseover = false"
    >
      <user-bar :has-collapse-button="!showOverlay" :sidebar-data="sidebarData" />
      <div v-if="showTrialStatusWidget" class="gl-px-2 gl-py-2">
        <trial-status-widget
          class="gl-rounded-base gl-relative gl-display-flex gl-align-items-center gl-mb-1 gl-px-3 gl-line-height-normal gl-text-black-normal! gl-hover-bg-t-gray-a-08 gl-focus-bg-t-gray-a-08 gl-text-decoration-none! gl-py-3"
        />
        <trial-status-popover />
      </div>
      <div
        class="contextual-nav gl-display-flex gl-flex-direction-column gl-flex-grow-1 gl-overflow-hidden"
      >
        <div class="gl-flex-grow-1 gl-overflow-auto" data-testid="nav-container">
          <div class="gl-px-5 gl-pt-3 gl-pb-2 gl-font-weight-bold gl-font-sm gl-text-gray-500">
            {{ sidebarData.current_context_header }}
          </div>

          <sidebar-menu
            v-if="menuItems.length"
            :items="menuItems"
            :is-logged-in="sidebarData.is_logged_in"
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
    </nav>
    <a
      v-for="shortcutLink in sidebarData.shortcut_links"
      :key="shortcutLink.href"
      :href="shortcutLink.href"
      :class="shortcutLink.css_class"
      class="gl-display-none"
    >
      {{ shortcutLink.title }}
    </a>

    <!--
      Only mount peek behavior components if the sidebar is peekable, to avoid
      setting up event listeners unnecessarily.
    -->
    <sidebar-peek-behavior
      v-if="sidebarState.isPeekable && !sidebarState.isHoverPeek"
      :is-mouse-over-sidebar="isMouseover"
      @change="onPeekChange"
    />
    <sidebar-hover-peek-behavior
      v-if="sidebarState.isPeekable && !sidebarState.isPeek"
      :is-mouse-over-sidebar="isMouseover"
      @change="onHoverPeekChange"
    />
  </div>
</template>
