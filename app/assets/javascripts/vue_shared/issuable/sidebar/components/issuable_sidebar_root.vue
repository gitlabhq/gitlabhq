<script>
import { GlIcon } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import Cookies from 'js-cookie';
import { parseBoolean } from '~/lib/utils/common_utils';
import { USER_COLLAPSED_GUTTER_COOKIE } from '../constants';

export default {
  components: {
    GlIcon,
  },
  data() {
    const userExpanded = !parseBoolean(Cookies.get(USER_COLLAPSED_GUTTER_COOKIE));

    // We're deliberately keeping two different props for sidebar status;
    // 1. userExpanded reflects value based on cookie `collapsed_gutter`.
    // 2. isExpanded reflect actual sidebar state.
    return {
      userExpanded,
      isExpanded: userExpanded ? bp.isDesktop() : userExpanded,
    };
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

      Cookies.set(USER_COLLAPSED_GUTTER_COOKIE, !this.userExpanded);
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
    <button
      class="toggle-right-sidebar-button js-toggle-right-sidebar-button w-100 gl-text-decoration-none! gl-display-flex gl-outline-0!"
      data-testid="toggle-right-sidebar-button"
      :title="__('Toggle sidebar')"
      @click="toggleSidebar"
    >
      <span v-if="isExpanded" class="collapse-text gl-flex-grow-1 gl-text-left">{{
        __('Collapse sidebar')
      }}</span>
      <gl-icon v-show="isExpanded" data-testid="icon-collapse" name="chevron-double-lg-right" />
      <gl-icon
        v-show="!isExpanded"
        data-testid="icon-expand"
        name="chevron-double-lg-left"
        class="gl-ml-2"
      />
    </button>
    <div data-testid="sidebar-items" class="issuable-sidebar">
      <slot
        name="right-sidebar-items"
        v-bind="{ sidebarExpanded: isExpanded, toggleSidebar }"
      ></slot>
    </div>
  </aside>
</template>
