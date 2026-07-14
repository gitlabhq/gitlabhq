<script>
import { GlIntersectionObserver, GlLoadingIcon } from '@gitlab/ui';
import PageHeading from './page_heading.vue';

export default {
  name: 'BaseLayout',
  components: {
    GlIntersectionObserver,
    GlLoadingIcon,
    PageHeading,
  },
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
  methods: {
    syncStickyHeaderHeight() {
      const el = this.$refs.stickyHeader;
      if (!el) return;
      document.documentElement.style.setProperty(
        '--layout-sticky-header-height',
        `${el.offsetHeight}px`,
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
    >
      <template v-if="$scopedSlots['heading-wrapper']" #heading-wrapper>
        <slot name="heading-wrapper"></slot>
      </template>
      <template v-if="$scopedSlots.heading" #heading>
        <slot name="heading"></slot>
      </template>
      <template v-if="$scopedSlots.actions" #actions>
        <slot name="actions"></slot>
      </template>
      <template v-if="$scopedSlots.description || description" #description>
        <slot v-if="$scopedSlots.description" name="description"></slot>
        <template v-else>{{ description }}</template>
      </template>
    </page-heading>

    <gl-intersection-observer
      v-if="$scopedSlots['sticky-header']"
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
      v-if="$scopedSlots.alerts"
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
