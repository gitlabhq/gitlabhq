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
    this.contentResizeObserver?.disconnect();
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

      // Re-measure when content above the sidebar changes height after mount.
      this.contentResizeObserver?.disconnect();
      if (typeof ResizeObserver !== 'undefined') {
        this.contentResizeObserver = new ResizeObserver(this.scheduleSyncSidebarSpace);
        this.contentResizeObserver.observe(this.$el);
      }

      this.syncSidebarSpace();
    },
    onStickyChange() {
      // The sticky header height moves the stuck sidebar without a scroll event.
      this.scheduleSyncSidebarSpace();
    },
    scheduleSyncSidebarSpace() {
      // Coalesce bursts of scroll/resize events into one measurement per frame.
      cancelAnimationFrame(this.syncFrame);
      this.syncFrame = requestAnimationFrame(this.syncSidebarSpace);
    },
    syncSidebarSpace() {
      const { sidebar } = this.$refs;
      if (!sidebar || !this.scrollContainer) return;

      const space = this.measureSidebarSpace(sidebar);
      sidebar.style.setProperty('--detail-layout-sidebar-space', `${Math.max(space, 0)}px`);
    },
    measureSidebarSpace(sidebar) {
      const container = this.scrollContainer;
      const containerRect = container.getBoundingClientRect();
      const style = window.getComputedStyle(sidebar);

      if (style.position !== 'sticky') {
        return sidebar.getBoundingClientRect().top - containerRect.top;
      }

      // Derived from the layout, not the sidebar's own rect, which can be stale mid-scroll.
      // The sticky inset applies to the border box, so the margin only affects naturalTop.
      const scrollportTop = containerRect.top + container.clientTop;
      const marginTop = parseFloat(style.marginTop) || 0;
      const inset = parseFloat(style.top);
      const naturalTop = sidebar.parentElement.getBoundingClientRect().top + marginTop;
      const stuckTop = Number.isNaN(inset) ? -Infinity : scrollportTop + inset;

      return Math.max(naturalTop, stuckTop) - scrollportTop;
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
    @sticky-change="onStickyChange"
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
