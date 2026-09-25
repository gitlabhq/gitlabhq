<script>
import { debounce, isEqual } from 'lodash-es';
import { GlIntersectionObserver, GlLoadingIcon } from '@gitlab/ui';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';
import PageHeading from './page_heading.vue';

export default {
  name: 'BaseLayout',
  components: {
    GlIntersectionObserver,
    GlLoadingIcon,
    PageHeading,
  },
  mixins: [glSlotsMixin],
  SCROLL_CONTAINER_SELECTOR: '.panel-content-inner',
  inject: {
    // Provided by an ancestor DynamicPanel. Falls back to the gon default when
    // the layout is rendered outside a panel (for example in work items).
    // `fluidLayout` is static per panel/page, so a one-time injected value is enough.
    isFluidLayout: {
      from: 'fluidLayout',
      default: () => window.gon?.fluid_layout ?? false,
    },
  },
  props: {
    heading: {
      type: String,
      required: false,
      default: null,
    },
    headingTag: {
      type: String,
      required: false,
      default: null,
      validator: (value) => value === null || ['h1', 'h2'].includes(value),
    },
    description: {
      type: String,
      required: false,
      default: null,
    },
    pageHeadingSrOnly: {
      type: Boolean,
      required: false,
      default: false,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isStuck: false,
      observerOptions: null,
      // Bumped whenever observerOptions change, to remount the observer (via :key)
      // so it re-reads options, which GlIntersectionObserver only reads once.
      observerKey: 0,
    };
  },
  watch: {
    isStuck: {
      handler(isStuck) {
        if (isStuck) {
          this.$nextTick(() => {
            this.syncStickyHeaderHeight();
          });
        } else {
          document.documentElement.style.removeProperty('--layout-sticky-header-height');
        }
      },
    },
  },
  mounted() {
    if (this.glSlots()['sticky-header']) {
      // The sticky header's height (and thus rootMargin) can change after mount from
      // responsive breakpoints, web font load, or dynamic slot content. A
      // ResizeObserver on the header catches all of these, unlike a window resize.
      this.debouncedSyncObserverOptions = debounce(
        this.syncObserverOptions,
        DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
      );
      this.stickyHeaderResizeObserver = new ResizeObserver(this.debouncedSyncObserverOptions);
      this.observeStickyHeader();
      this.syncObserverOptions();
    }
  },
  beforeDestroy() {
    this.stickyHeaderResizeObserver?.disconnect();
    this.debouncedSyncObserverOptions?.cancel();
  },
  methods: {
    syncObserverOptions() {
      const root = this.$el.closest(this.$options.SCROLL_CONTAINER_SELECTOR);
      const options = {};
      // Null root falls back to the viewport, e.g. when not inside a panel.
      if (root) options.root = root;

      const rootMargin = this.stickyHeaderRootMargin();
      if (rootMargin) options.rootMargin = rootMargin;

      const nextOptions = Object.keys(options).length ? options : null;
      if (isEqual(nextOptions, this.observerOptions)) return;

      this.observerOptions = nextOptions;
      // Remounting the observer via :key recreates the sticky-header element, so
      // re-point the ResizeObserver at the new one once it has rendered.
      this.observerKey += 1;
      this.$nextTick(this.observeStickyHeader);
    },
    observeStickyHeader() {
      const el = this.$refs.stickyHeader;
      if (!this.stickyHeaderResizeObserver || !el) return;
      this.stickyHeaderResizeObserver.disconnect();
      this.stickyHeaderResizeObserver.observe(el);
    },
    stickyHeaderRootMargin() {
      const el = this.$refs.stickyHeader;
      if (!el) return null;

      // Sticky header height without its bottom padding spacer, so the header sticks
      // as the heading reaches where the sticky header's content bottom will sit.
      const { paddingBottom } = window.getComputedStyle(el);
      const offset = el.offsetHeight - (parseFloat(paddingBottom) || 0);
      if (offset <= 0) return null;

      // eslint-disable-next-line @gitlab/require-i18n-strings -- CSS rootMargin value, not user-facing
      return `-${offset}px 0px 0px 0px`;
    },
    syncStickyHeaderHeight() {
      const el = this.$refs.stickyHeader;
      if (!el) return;
      const heightPx = `${el.offsetHeight}px`;
      // Offsets content while the header is showing; removed when it hides.
      document.documentElement.style.setProperty('--layout-sticky-header-height', heightPx);
      // Set once and never removed, so consumers can reserve a stable header
      // height (e.g. detail-layout's sticky sidebar) without the value toggling
      // on scroll, which would resize the sidebar and stutter the UI.
      document.documentElement.style.setProperty(
        '--layout-sticky-header-reserved-height',
        heightPx,
      );
    },
  },
};
</script>

<template>
  <div class="gl-base-layout" :class="{ 'gl-base-layout-header-is-stuck': isStuck }">
    <slot name="before"></slot>

    <page-heading
      :heading="heading"
      :heading-tag="headingTag"
      :class="{ 'gl-sr-only': pageHeadingSrOnly }"
      inline-actions
    >
      <template v-if="glSlots()['heading-wrapper']" #heading-wrapper>
        <slot name="heading-wrapper"></slot>
      </template>
      <template v-if="glSlots().heading" #heading>
        <slot name="heading"></slot>
      </template>
      <template v-if="glSlots().actions" #actions>
        <slot name="actions"></slot>
      </template>
      <template v-if="glSlots().description || description" #description>
        <slot v-if="glSlots().description" name="description"></slot>
        <template v-else>{{ description }}</template>
      </template>
    </page-heading>

    <gl-intersection-observer
      v-if="glSlots()['sticky-header']"
      :key="observerKey"
      :options="observerOptions"
      @appear="isStuck = false"
      @disappear="isStuck = true"
    >
      <div
        ref="stickyHeader"
        class="gl-base-layout-sticky-header"
        data-testid="base-layout-sticky-header"
      >
        <div
          class="gl-base-layout-sticky-header-inner"
          :class="{ 'container-fluid container-limited': !isFluidLayout }"
        >
          <slot name="sticky-header"></slot>
        </div>
      </div>
    </gl-intersection-observer>

    <div
      v-if="glSlots().alerts"
      class="gl-base-layout-alerts js-base-layout-alerts"
      data-testid="base-layout-alerts"
    >
      <slot name="alerts"></slot>
    </div>
    <div data-testid="base-layout-content">
      <slot v-if="loading" name="loading">
        <gl-loading-icon class="gl-base-layout-loading-icon" size="lg" />
      </slot>
      <slot v-else name="content">
        <slot></slot>
      </slot>
    </div>
  </div>
</template>
