<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { getCookie, setCookie, parseBoolean } from '~/lib/utils/common_utils';
import { __ } from '~/locale';

import { USER_COLLAPSED_GUTTER_COOKIE } from '../constants';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  data() {
    const userExpanded = !parseBoolean(getCookie(USER_COLLAPSED_GUTTER_COOKIE));

    // We're deliberately keeping two different props for sidebar status;
    // 1. userExpanded reflects value based on cookie `collapsed_gutter`.
    // 2. isExpanded reflect actual sidebar state.
    return {
      userExpanded,
      isExpanded: userExpanded ? bp.isDesktop() : userExpanded,
    };
  },
  computed: {
    toggleLabel() {
      return this.isExpanded ? __('Collapse sidebar') : __('Expand sidebar');
    },
    toggleIcon() {
      return this.isExpanded ? 'chevron-double-lg-right' : 'chevron-double-lg-left';
    },
    expandedToggleClass() {
      return this.isExpanded ? 'block' : '';
    },
    collapsedToggleClass() {
      return !this.isExpanded ? 'block' : '';
    },
  },
  mounted() {
    window.addEventListener('resize', this.handleWindowResize);
    this.updatePageContainerClass();
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.handleWindowResize);
  },
  methods: {
    updatePageContainerClass() {
      const layoutPageEl = document.querySelector('.layout-page');

      if (layoutPageEl) {
        layoutPageEl.classList.toggle('right-sidebar-expanded', this.isExpanded);
        layoutPageEl.classList.toggle('right-sidebar-collapsed', !this.isExpanded);
      }
    },
    handleWindowResize() {
      if (this.userExpanded) {
        this.isExpanded = bp.isDesktop();
        this.updatePageContainerClass();
      }
    },
    toggleSidebar() {
      this.isExpanded = !this.isExpanded;
      this.userExpanded = this.isExpanded;

      setCookie(USER_COLLAPSED_GUTTER_COOKIE, !this.userExpanded);
      this.updatePageContainerClass();
    },
  },
};
</script>

<template>
  <aside
    :class="{ 'right-sidebar-expanded': isExpanded, 'right-sidebar-collapsed': !isExpanded }"
    class="right-sidebar"
    aria-live="polite"
  >
    <div class="right-sidebar-header" :class="expandedToggleClass">
      <gl-button
        v-gl-tooltip.hover.left
        category="tertiary"
        size="small"
        class="gutter-toggle toggle-right-sidebar-button js-toggle-right-sidebar-button gl-float-right !gl-shadow-none"
        :class="collapsedToggleClass"
        data-testid="toggle-right-sidebar-button"
        :icon="toggleIcon"
        :title="toggleLabel"
        :aria-label="toggleLabel"
        @click="toggleSidebar"
      />
      <slot
        name="right-sidebar-top-items"
        v-bind="{ sidebarExpanded: isExpanded, toggleSidebar }"
      ></slot>
    </div>
    <div data-testid="sidebar-items" class="issuable-sidebar">
      <slot
        name="right-sidebar-items"
        v-bind="{ sidebarExpanded: isExpanded, toggleSidebar }"
      ></slot>
    </div>
  </aside>
</template>
