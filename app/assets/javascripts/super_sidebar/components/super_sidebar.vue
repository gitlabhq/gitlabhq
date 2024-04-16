<script>
import { GlButton } from '@gitlab/ui';
import { GlBreakpointInstance, breakpoints } from '@gitlab/ui/dist/utils';
import ExtraInfo from 'jh_else_ce/super_sidebar/components/extra_info.vue';
import { Mousetrap } from '~/lib/mousetrap';
import { TAB_KEY_CODE } from '~/lib/utils/keycodes';
import { keysFor, TOGGLE_SUPER_SIDEBAR } from '~/behaviors/shortcuts/keybindings';
import { __, s__ } from '~/locale';
import Tracking from '~/tracking';
import {
  sidebarState,
  JS_TOGGLE_EXPAND_CLASS,
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
import ScrollScrim from './scroll_scrim.vue';

export default {
  components: {
    GlButton,
    UserBar,
    HelpCenter,
    ExtraInfo,
    SidebarMenu,
    SidebarPeekBehavior,
    SidebarHoverPeekBehavior,
    SidebarPortalTarget,
    ScrollScrim,
    TrialStatusWidget: () =>
      import('ee_component/contextual_sidebar/components/trial_status_widget.vue'),
    TrialStatusPopover: () =>
      import('ee_component/contextual_sidebar/components/trial_status_popover.vue'),
  },
  mixins: [Tracking.mixin()],
  i18n: {
    skipToMainContent: __('Skip to main content'),
    primaryNavigation: s__('Navigation|Primary navigation'),
    adminArea: s__('Navigation|Admin Area'),
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
  watch: {
    'sidebarState.isCollapsed': {
      handler(collapsed) {
        this.setupFocusTrapListener();

        if (this.isOverlappingAndNotPeeking() && !collapsed) {
          this.$nextTick(() => {
            this.firstFocusableElement().focus();
          });
        }
      },
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
    this.setupFocusTrapListener();
    Mousetrap.bind(keysFor(TOGGLE_SUPER_SIDEBAR), this.toggleSidebar);
  },
  beforeDestroy() {
    document.removeEventListener('keydown', this.focusTrap);
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
    isOverlapping() {
      return GlBreakpointInstance.windowWidth() < breakpoints.xl;
    },
    isOverlappingAndNotPeeking() {
      return this.isOverlapping() && !(sidebarState.isHoverPeek || sidebarState.isPeek);
    },
    setupFocusTrapListener() {
      /**
       * Only trap focus when sidebar displays over page content to avoid
       * focus moving to page content and being obscured by the sidebar
       */
      if (this.isOverlapping() && !this.sidebarState.isCollapsed) {
        document.addEventListener('keydown', this.focusTrap);
      } else {
        document.removeEventListener('keydown', this.focusTrap);
      }
    },
    collapseSidebar() {
      toggleSuperSidebarCollapsed(true, false);
    },
    handleEscKey() {
      if (this.isOverlappingAndNotPeeking()) {
        this.collapseSidebar();
        document.querySelector(`.${JS_TOGGLE_EXPAND_CLASS}`)?.focus();
      }
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
    firstFocusableElement() {
      return this.$refs.userBar.$el.querySelector('a');
    },
    lastFocusableElement() {
      if (this.sidebarData.is_admin) {
        return this.$refs.adminAreaLink.$el;
      }
      return this.$refs.helpCenter.$el.querySelector('button');
    },
    focusTrap(event) {
      const { keyCode, shiftKey } = event;
      const firstFocusableElement = this.firstFocusableElement();
      const lastFocusableElement = this.lastFocusableElement();

      if (keyCode !== TAB_KEY_CODE) return;

      if (shiftKey) {
        if (document.activeElement === firstFocusableElement) {
          lastFocusableElement.focus();
          event.preventDefault();
        }
      } else if (document.activeElement === lastFocusableElement) {
        firstFocusableElement.focus();
        event.preventDefault();
      }
    },
  },
};
</script>

<template>
  <div>
    <div ref="overlay" class="super-sidebar-overlay" @click="collapseSidebar"></div>
    <gl-button
      v-if="sidebarData.is_logged_in"
      class="super-sidebar-skip-to gl-sr-only-focusable gl-fixed gl-left-0 gl-m-3"
      data-testid="super-sidebar-skip-to"
      href="#content-body"
      variant="confirm"
    >
      {{ $options.i18n.skipToMainContent }}
    </gl-button>
    <nav
      id="super-sidebar"
      aria-labelledby="super-sidebar-heading"
      class="super-sidebar"
      :class="peekClasses"
      data-testid="super-sidebar"
      :inert="sidebarState.isCollapsed"
      @mouseenter="isMouseover = true"
      @mouseleave="isMouseover = false"
      @keydown.esc="handleEscKey"
    >
      <h2 id="super-sidebar-heading" class="gl-sr-only">
        {{ $options.i18n.primaryNavigation }}
      </h2>
      <user-bar ref="userBar" :has-collapse-button="!showOverlay" :sidebar-data="sidebarData" />
      <div v-if="showTrialStatusWidget" class="gl-px-2 gl-py-2">
        <trial-status-widget
          class="super-sidebar-nav-item gl-rounded-base gl-relative gl-display-flex gl-align-items-center gl-mb-1 gl-px-3 gl-line-height-normal gl-text-black-normal! gl-text-decoration-none! gl-py-3"
        />
        <trial-status-popover />
      </div>
      <div
        class="contextual-nav gl-display-flex gl-flex-direction-column gl-flex-grow-1 gl-overflow-hidden"
      >
        <scroll-scrim class="gl-flex-grow-1" data-testid="nav-container">
          <div
            v-if="sidebarData.current_context_header"
            id="super-sidebar-context-header"
            class="gl-px-5 gl-pt-3 gl-pb-2 gl-m-0 gl-reset-line-height gl-font-weight-bold gl-font-sm super-sidebar-context-header"
          >
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
        </scroll-scrim>
        <div class="gl-p-2">
          <help-center ref="helpCenter" :sidebar-data="sidebarData" />
          <gl-button
            v-if="sidebarData.is_admin"
            ref="adminAreaLink"
            class="gl-fixed gl-right-0 gl-mr-3 gl-mt-2"
            data-testid="sidebar-admin-link"
            :href="sidebarData.admin_url"
            icon="admin"
            size="small"
          >
            {{ $options.i18n.adminArea }}
          </gl-button>
          <extra-info />
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
