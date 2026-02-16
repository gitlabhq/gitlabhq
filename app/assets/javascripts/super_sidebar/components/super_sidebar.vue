<script>
import { computed } from 'vue';
import { GlTooltipDirective } from '@gitlab/ui';
import { GlBreakpointInstance, breakpoints } from '@gitlab/ui/src/utils'; // eslint-disable-line no-restricted-syntax -- GlBreakpointInstance is used intentionally here. In this case we must obtain viewport breakpoints
import { Mousetrap } from '~/lib/mousetrap';
import { TAB_KEY_CODE } from '~/lib/utils/keycodes';
import { keysFor, TOGGLE_SUPER_SIDEBAR } from '~/behaviors/shortcuts/keybindings';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import { sidebarState, JS_TOGGLE_EXPAND_CLASS } from '../constants';
import {
  isCollapsed,
  toggleSuperSidebarCollapsed,
  toggleSuperSidebarIconOnly,
} from '../super_sidebar_collapsed_state_manager';
import { trackContextAccess } from '../utils';
import SidebarPortalTarget from './sidebar_portal_target.vue';
import IconOnlyToggle from './icon_only_toggle.vue';
import HelpCenter from './help_center.vue';
import SidebarMenu from './sidebar_menu.vue';
import ScrollScrim from './scroll_scrim.vue';

export default {
  components: {
    IconOnlyToggle,
    HelpCenter,
    SidebarMenu,
    SidebarPortalTarget,
    ScrollScrim,
    TrialWidget: () => import('jh_else_ee/contextual_sidebar/components/trial_widget.vue'),
    TierBadge: () => import('ee_component/vue_shared/components/tier_badge/tier_badge.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin()],
  i18n: {
    primaryNavigation: s__('Navigation|Primary navigation'),
  },
  inject: ['showTrialWidget'],
  provide() {
    return {
      isIconOnly: computed(() => this.isIconOnly),
      primaryCtaLink: this.sidebarData.tier_badge_href,
    };
  },
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
      isAnimatable: false,
      wasToggledManually: false,
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
        'super-sidebar-is-icon-only': this.isIconOnly,
        'super-sidebar-is-mobile': this.sidebarState.isMobile,
        'super-sidebar-animatable': this.isAnimatable,
        'super-sidebar-toggled-manually': this.wasToggledManually,
      };
    },
    canIconOnly() {
      return !this.sidebarState.isMobile;
    },
    isIconOnly() {
      return this.canIconOnly && this.sidebarState.isIconOnly;
    },
    showTierBadge() {
      return Boolean(this.sidebarData.tier_badge_href);
    },
  },
  watch: {
    'sidebarState.isCollapsed': {
      handler(collapsed) {
        this.setupFocusTrapListener();

        if (this.isNotPeeking() && !collapsed) {
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

    this.$nextTick(() => {
      this.isAnimatable = true;
    });
  },
  beforeDestroy() {
    document.removeEventListener('keydown', this.focusTrap);
    Mousetrap.unbind(keysFor(TOGGLE_SUPER_SIDEBAR));
  },
  methods: {
    toggleSidebar() {
      if (this.canIconOnly) {
        this.wasToggledManually = true;
        toggleSuperSidebarIconOnly();
      } else {
        // on mobile
        toggleSuperSidebarCollapsed(!isCollapsed());
      }
    },
    isOverlapping() {
      return GlBreakpointInstance.windowWidth() < breakpoints.xl;
    },
    isNotPeeking() {
      return !(sidebarState.isHoverPeek || sidebarState.isPeek);
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
      toggleSuperSidebarCollapsed(true);
    },
    handleEscKey() {
      if (this.isOverlapping() && this.isNotPeeking()) {
        this.collapseSidebar();
        document.querySelector(`.${JS_TOGGLE_EXPAND_CLASS}`)?.focus();
      }
    },
    firstFocusableElement() {
      return this.$refs.sidebarMenu.$el.querySelector('a');
    },
    lastFocusableElement() {
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
    handleTransitionEnd() {
      this.wasToggledManually = false;
    },
  },
};
</script>

<template>
  <div v-if="menuItems.length" class="super-sidebar-wrapper">
    <div ref="overlay" class="super-sidebar-overlay" @click="collapseSidebar"></div>
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
      @transitionend="handleTransitionEnd"
    >
      <h2 id="super-sidebar-heading" class="gl-sr-only">
        {{ $options.i18n.primaryNavigation }}
      </h2>
      <div class="contextual-nav gl-flex gl-grow gl-flex-col gl-overflow-hidden">
        <div
          v-if="sidebarData.current_context_header && !isIconOnly"
          id="super-sidebar-context-header"
          class="super-sidebar-context-header gl-m-0 gl-flex gl-justify-between gl-px-5 gl-py-3 gl-font-bold gl-leading-reset"
        >
          {{ sidebarData.current_context_header }}
          <tier-badge v-if="showTierBadge" data-testid="sidebar-tier-badge" is-upgrade />
        </div>
        <scroll-scrim class="gl-grow" data-testid="nav-container">
          <sidebar-menu
            v-if="menuItems.length"
            ref="sidebarMenu"
            :items="menuItems"
            :is-logged-in="sidebarData.is_logged_in"
            :panel-type="sidebarData.panel_type"
            :pinned-item-ids="sidebarData.pinned_items"
            :update-pins-url="sidebarData.update_pins_url"
          />
          <sidebar-portal-target />
        </scroll-scrim>
        <div v-if="showTrialWidget && !isIconOnly" class="gl-p-2">
          <trial-widget
            class="gl-relative gl-mb-1 gl-flex gl-items-center gl-rounded-[.75rem] gl-p-3 gl-leading-normal !gl-text-default !gl-no-underline"
          />
        </div>
        <help-center
          v-if="canIconOnly"
          ref="helpCenter"
          :sidebar-data="sidebarData"
          class="gl-p-3"
        />
        <div v-else class="gl-p-2">
          <div class="gl-flex gl-flex-col gl-justify-end">
            <help-center ref="helpCenter" :sidebar-data="sidebarData" class="gl-mr-2" />
          </div>
        </div>
        <icon-only-toggle v-if="canIconOnly" class="gl-hidden xl:gl-flex" @toggle="toggleSidebar" />
      </div>
    </nav>
    <a
      v-for="shortcutLink in sidebarData.shortcut_links"
      :key="shortcutLink.href"
      :href="shortcutLink.href"
      :class="shortcutLink.css_class"
      class="gl-hidden"
    >
      {{ shortcutLink.title }}
    </a>
  </div>
</template>
