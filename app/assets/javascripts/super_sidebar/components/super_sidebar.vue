<script>
import { computed, defineAsyncComponent } from 'vue';
import { GlBreakpointInstance, breakpoints } from '@gitlab/ui/src/utils'; // eslint-disable-line no-restricted-syntax -- GlBreakpointInstance is used intentionally here. In this case we must obtain viewport breakpoints
import { PortalTarget } from 'portal-vue';
import { Mousetrap } from '~/lib/mousetrap';
import { TAB_KEY_CODE } from '~/lib/utils/keycodes';
import { keysFor, TOGGLE_SUPER_SIDEBAR } from '~/behaviors/shortcuts/keybindings';
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import AccessorUtilities from '~/lib/utils/accessor';
import {
  JS_TOGGLE_EXPAND_CLASS,
  PANEL_TYPES,
  PANELS_WITH_HIDEABLE_UNPINNED_ITEMS,
  SETTINGS_DISCLOSURE_PORTAL_NAME,
  SIDEBAR_NAV_MODE_PINNED_ONLY,
  SIDEBAR_NAV_MODE_ALL_CATEGORIES,
  SIDEBAR_NAV_MODE_GROUPED_PINS,
  SIDEBAR_NAV_MODES,
  SIDEBAR_NAV_MODE_STORAGE_KEY,
} from '../constants';
import { sidebarState } from '../state';
import {
  isCollapsed,
  toggleSuperSidebarCollapsed,
  toggleSuperSidebarIconOnly,
} from '../super_sidebar_collapsed_state_manager';
import { trackContextAccess } from '../utils';
import IconOnlyToggle from './icon_only_toggle.vue';
import ManageOrganizationButton from './manage_organization_button.vue';
import HelpCenter from './help_center.vue';
import SidebarMenu from './sidebar_menu.vue';
import SidebarPreferences from './sidebar_preferences.vue';
import ScrollScrim from './scroll_scrim.vue';

export default {
  name: 'SuperSidebar',
  components: {
    IconOnlyToggle,
    ManageOrganizationButton,
    HelpCenter,
    SidebarMenu,
    SidebarPreferences,
    ScrollScrim,
    PortalTarget,
    TrialWidget: defineAsyncComponent(
      () => import('jh_else_ee/contextual_sidebar/components/trial_widget.vue'),
    ),
  },
  mixins: [glFeatureFlagsMixin()],
  settingsDisclosurePortalName: SETTINGS_DISCLOSURE_PORTAL_NAME,
  i18n: {
    primaryNavigation: s__('Navigation|Primary navigation'),
  },
  inject: ['showTrialWidget'],
  provide() {
    return {
      isIconOnly: computed(() => this.isIconOnly),
      panelType: this.sidebarData.panel_type,
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
      isMouseover: false,
      isAnimatable: false,
      wasToggledManually: false,
      // User's chosen navigation mode (persisted), one of SIDEBAR_NAV_MODE_*.
      // The three modes are mutually exclusive by construction.
      navMode: this.readNavMode(),
    };
  },
  computed: {
    menuItems() {
      return this.sidebarData.current_menu_items || [];
    },
    sidebarClasses() {
      return {
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
    manageOrganizationPath() {
      return this.sidebarData.manage_organization_link;
    },
    isInOrganizationAdminArea() {
      return this.sidebarData.panel_type === PANEL_TYPES.ORGANIZATION_ADMIN;
    },
    panelType() {
      return this.sidebarData.panel_type;
    },
    // Mirror of SidebarMenu#showUnpinnedItems: the control only makes sense when
    // the flag hides unpinned items for a pinnable, non-organization panel.
    canToggleOldCategories() {
      return (
        this.glFeatures.hideUnpinnedSidebarItems &&
        PANELS_WITH_HIDEABLE_UNPINNED_ITEMS.includes(this.panelType)
      );
    },
    // SidebarMenu still consumes two independent booleans; derive them from the
    // single navMode so the mutual exclusivity is guaranteed by construction.
    showOldCategories() {
      return this.navMode === SIDEBAR_NAV_MODE_ALL_CATEGORIES;
    },
    groupPinned() {
      return this.navMode === SIDEBAR_NAV_MODE_GROUPED_PINS;
    },
    // Settings portals into the context header when it renders, else the footer.
    showHeaderSettingsDisclosure() {
      return (
        this.glFeatures.hideUnpinnedSidebarItems &&
        Boolean(this.sidebarData.current_context_header) &&
        !this.isIconOnly
      );
    },
    showFooterSettingsDisclosure() {
      return this.glFeatures.hideUnpinnedSidebarItems && !this.showHeaderSettingsDisclosure;
    },
  },
  watch: {
    'sidebarState.isCollapsed': {
      handler(collapsed) {
        this.setupFocusTrapListener();

        if (!collapsed) {
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
    } = this.sidebarData;
    if (isLoggedIn && currentContext.namespace) {
      trackContextAccess(username, currentContext);
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
      if (this.isOverlapping()) {
        this.collapseSidebar();
        document.querySelector(`.${JS_TOGGLE_EXPAND_CLASS}`)?.focus();
      }
    },
    firstFocusableElement() {
      // Falls back to the always-present Help Center toggle, so focus lands
      // somewhere even when the menu has no links (e.g. unpinned items hidden).
      return this.$refs.sidebarMenu.$el.querySelector('a') || this.lastFocusableElement();
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
    readNavMode() {
      if (!AccessorUtilities.canUseLocalStorage()) return SIDEBAR_NAV_MODE_PINNED_ONLY;

      const stored = localStorage.getItem(SIDEBAR_NAV_MODE_STORAGE_KEY);

      return SIDEBAR_NAV_MODES.includes(stored) ? stored : SIDEBAR_NAV_MODE_PINNED_ONLY;
    },
    setNavMode(mode) {
      this.navMode = mode;
      if (AccessorUtilities.canUseLocalStorage()) {
        localStorage.setItem(SIDEBAR_NAV_MODE_STORAGE_KEY, mode);
      }
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
      :class="sidebarClasses"
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
      <div class="contextual-nav gl-flex gl-grow gl-flex-col gl-overflow-hidden gl-pt-2">
        <div
          v-if="sidebarData.current_context_header && !isIconOnly"
          id="super-sidebar-context-header"
          class="super-sidebar-context-header gl-m-0 gl-flex gl-items-center gl-gap-2 gl-px-5 gl-py-3 gl-font-bold gl-leading-reset"
        >
          <span id="super-sidebar-context-header-title" class="gl-min-w-0 gl-grow">{{
            sidebarData.current_context_header
          }}</span>
          <portal-target
            v-if="showHeaderSettingsDisclosure"
            :name="$options.settingsDisclosurePortalName"
            class="gl-shrink-0"
          />
          <sidebar-preferences v-if="canToggleOldCategories" :mode="navMode" @select="setNavMode" />
        </div>
        <scroll-scrim class="gl-grow" data-testid="nav-container">
          <sidebar-menu
            v-if="menuItems.length"
            ref="sidebarMenu"
            :items="menuItems"
            :is-logged-in="sidebarData.is_logged_in"
            :panel-type="sidebarData.panel_type"
            :pinned-item-ids="sidebarData.pinned_items"
            :show-feature-library-shimmer="sidebarData.show_feature_library_shimmer"
            :show-old-categories="showOldCategories"
            :group-pinned="groupPinned"
            :settings-in-header="showHeaderSettingsDisclosure"
          />
        </scroll-scrim>
        <portal-target
          v-if="showFooterSettingsDisclosure"
          :name="$options.settingsDisclosurePortalName"
          class="gl-px-3"
        />
        <div v-if="showTrialWidget && !isIconOnly" class="gl-p-2">
          <trial-widget
            class="gl-relative gl-mb-1 gl-flex gl-items-center gl-rounded-[.75rem] gl-p-3 gl-leading-normal !gl-text-default !gl-no-underline"
          />
        </div>
        <div v-if="manageOrganizationPath" class="gl-px-3 gl-pt-3">
          <manage-organization-button
            :href="manageOrganizationPath"
            :is-exit="isInOrganizationAdminArea"
          />
        </div>
        <help-center
          v-if="canIconOnly"
          ref="helpCenter"
          :sidebar-data="sidebarData"
          class="gl-p-3"
          :class="{ 'gl-pt-0': glFeatures.hideUnpinnedSidebarItems }"
        />
        <div v-else class="gl-p-2">
          <div class="gl-flex gl-flex-col gl-justify-end">
            <help-center ref="helpCenter" :sidebar-data="sidebarData" class="gl-mr-2" />
          </div>
        </div>
        <div v-if="canIconOnly" class="-gl-mt-2 gl-hidden gl-px-3 gl-pb-3 xl:gl-block">
          <icon-only-toggle @toggle="toggleSidebar" />
        </div>
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
