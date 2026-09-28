<script>
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';
import BaseLayout from './base_layout.vue';

const SCROLL_CONTAINER_SELECTOR = '.panel-content-inner';

export default {
  name: 'DetailLayout',
  components: { BaseLayout },
  mixins: [glSlotsMixin],
  props: {
    ...BaseLayout.props,
    showSidebar: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  watch: {
    loading() {
      // The sidebar only renders once loading is done, so (re-)wire against it then.
      this.$nextTick(this.setupSidebarSync);
    },
  },
  mounted() {
    this.$nextTick(this.setupSidebarSync);
    window.addEventListener('resize', this.scheduleSyncSidebarSpace);
  },
  beforeDestroy() {
    cancelAnimationFrame(this.syncFrame);
    this.scrollContainer?.removeEventListener('scroll', this.scheduleSyncSidebarSpace);
    window.removeEventListener('resize', this.scheduleSyncSidebarSpace);
  },
  methods: {
    setupSidebarSync() {
      const scrollContainer = this.$refs.sidebar?.closest(SCROLL_CONTAINER_SELECTOR);
      if (!scrollContainer || scrollContainer === this.scrollContainer) return;

      // Detach from a previously resolved container so it can't leak a listener.
      this.scrollContainer?.removeEventListener('scroll', this.scheduleSyncSidebarSpace);
      this.scrollContainer = scrollContainer;
      this.scrollContainer.addEventListener('scroll', this.scheduleSyncSidebarSpace, {
        passive: true,
      });
      this.syncSidebarSpace();
    },
    scheduleSyncSidebarSpace() {
      // Coalesce bursts of scroll/resize events into one measurement per frame.
      cancelAnimationFrame(this.syncFrame);
      this.syncFrame = requestAnimationFrame(this.syncSidebarSpace);
    },
    syncSidebarSpace() {
      const { sidebar } = this.$refs;
      if (!sidebar || !this.scrollContainer) return;

      // Live distance from the scroll container's viewport top to the sidebar's
      // current top edge: the page heading when unscrolled, the sticky header once
      // stuck, and the correct in-between value while scrolling. Subtracting it from
      // the container height keeps the sidebar bottom at the viewport edge in every
      // scroll state, so its own scrollbar can always reach the last item.
      const space =
        sidebar.getBoundingClientRect().top - this.scrollContainer.getBoundingClientRect().top;
      sidebar.style.setProperty('--detail-layout-sidebar-space', `${Math.max(space, 0)}px`);
    },
  },
};
</script>

<template>
  <base-layout
    :heading="heading"
    :heading-tag="headingTag"
    :description="description"
    :page-heading-sr-only="pageHeadingSrOnly"
    :loading="loading"
    :animate-sticky-header="animateStickyHeader"
  >
    <template v-for="(_, name) in glSlots()" #[name]="slotProps">
      <slot :name="name" v-bind="slotProps || {}"></slot>
    </template>
    <template #content>
      <div
        class="gl-detail-layout-container"
        :class="{ 'gl-detail-layout-container-has-sidebar': glSlots().sidebar && showSidebar }"
        data-testid="detail-layout-container"
      >
        <div class="gl-detail-layout-content" data-testid="detail-layout-content">
          <slot></slot>
        </div>
        <div
          v-if="glSlots().sidebar"
          ref="sidebar"
          class="gl-detail-layout-sidebar"
          :class="{ 'gl-contents': !showSidebar }"
          data-testid="detail-layout-sidebar"
          tabindex="0"
          role="region"
          :aria-label="__('Sidebar')"
        >
          <slot name="sidebar"></slot>
        </div>
        <div
          v-if="glSlots().widgets"
          class="gl-detail-layout-widgets"
          data-testid="detail-layout-widgets"
        >
          <slot name="widgets"></slot>
        </div>
        <div
          v-if="glSlots().activity"
          class="gl-detail-layout-activity"
          data-testid="detail-layout-activity"
        >
          <slot name="activity"></slot>
        </div>
      </div>
    </template>
  </base-layout>
</template>
