<script>
import { uniqueId } from 'lodash-es';
import { PanelBreakpointInstance } from '~/panel_breakpoint_instance';
import { __ } from '~/locale';
import AccessiblePanelResizer from './accessible_panel_resizer.vue';
import { MIN_PANEL_PX } from './panel_constants';

// Fraction of the panels container. Derived from the container, not the
// viewport: the container excludes the navigation sidebar and the AI panel,
// so a panel can never be dragged over them.
const MAX_CONTAINER_FRACTION = 0.8;

const hasVisibleSibling = (targetEl) =>
  Array.from(targetEl.parentElement?.children ?? []).some(
    (el) => el !== targetEl && el.offsetWidth > 0,
  );

export default {
  name: 'PanelWidthResizer',
  MIN_PANEL_PX,
  components: {
    AccessiblePanelResizer,
  },
  props: {
    targetEl: {
      type: HTMLElement,
      required: true,
    },
    resizeLabel: {
      type: String,
      required: false,
      default: () => __('Resize panel'),
    },
    side: {
      type: String,
      required: false,
      default: 'left',
      validator: (v) => ['left', 'right'].includes(v),
    },
    hideWhenVisibleEl: {
      type: HTMLElement,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      handleId: uniqueId('panel-width-resizer-'),
      isDesktop: PanelBreakpointInstance.isDesktop(),
      dragWidth: null,
      containerWidth: 0,
      defaultPanelWidthPx: MIN_PANEL_PX,
      isTargetOverlay: false,
      isOverlapped: false,
      hasVisibleSibling: hasVisibleSibling(this.targetEl),
    };
  },
  computed: {
    showResizer() {
      return this.isDesktop && !this.isOverlapped && this.hasVisibleSibling;
    },
    rawMaxPx() {
      const available = this.containerWidth || window.innerWidth;
      const reserved = this.isTargetOverlay ? 0 : MIN_PANEL_PX;
      return Math.min(available * MAX_CONTAINER_FRACTION, available - reserved);
    },
    computedMaxPx() {
      return Math.max(MIN_PANEL_PX, this.rawMaxPx);
    },
    handleClasses() {
      return ['focus-visible:gl-focus', 'hover:!gl-bg-neutral-300'];
    },
  },
  watch: {
    dragWidth(width) {
      const { style } = this.targetEl;

      if (width == null) {
        style.width = '';
        style.flex = '';
      } else {
        style.width = `${width}px`;
        // eslint-disable-next-line @gitlab/require-i18n-strings -- CSS value, not user-facing
        style.setProperty('flex', '0 0 auto');
      }
    },
  },
  mounted() {
    window.addEventListener('resize', this.handleWindowResize);

    this.containerWidth = this.readContainerWidth();
    this.updateLayoutMode();

    // A previous drag's width may still be on the target; it survives
    // close/reopen. Clamp it: the container may have shrunk since.
    const inlineWidth = parseInt(this.targetEl.style.width, 10);
    if (inlineWidth) {
      this.dragWidth = inlineWidth;
      this.clampDragWidth();
    }

    this.updateOverlap();

    if (typeof ResizeObserver !== 'undefined') {
      this.observer = new ResizeObserver(() => {
        if (this.dragWidth == null) {
          this.defaultPanelWidthPx = this.readPanelWidth();
        }
        this.containerWidth = this.readContainerWidth();
        this.updateLayoutMode();
        this.clampDragWidth();
        this.updateOverlap();
      });
      this.observer.observe(this.targetEl);
      if (this.targetEl.parentElement) this.observer.observe(this.targetEl.parentElement);
      if (this.hideWhenVisibleEl) this.observer.observe(this.hideWhenVisibleEl);
    }

    this.$nextTick(() => {
      if (this.dragWidth == null) {
        this.defaultPanelWidthPx = this.readPanelWidth();
      }
      this.updateOverlap();
    });
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.handleWindowResize);
    this.observer?.disconnect();
  },
  methods: {
    readPanelWidth() {
      const { width } = this.targetEl.getBoundingClientRect();
      return width > 0 ? width : MIN_PANEL_PX;
    },
    readContainerWidth() {
      return this.targetEl.parentElement?.getBoundingClientRect().width || 0;
    },
    updateLayoutMode() {
      this.isTargetOverlay = getComputedStyle(this.targetEl).position === 'absolute';
    },
    clampDragWidth() {
      if (this.dragWidth == null) return;

      // When the container is too small to honor any pinned width (e.g. the
      // AI panel resized to its max), fall back to the responsive CSS
      if (this.containerWidth && this.rawMaxPx < MIN_PANEL_PX) {
        this.dragWidth = null;
        const { style } = this.targetEl;
        style.width = '';
        style.flex = '';
        return;
      }

      if (this.dragWidth > this.computedMaxPx) {
        this.dragWidth = this.computedMaxPx;
      }
    },
    updateOverlap() {
      this.isOverlapped = Boolean(this.hideWhenVisibleEl && this.hideWhenVisibleEl.offsetWidth > 0);
      this.hasVisibleSibling = hasVisibleSibling(this.targetEl);
    },
    handleWindowResize() {
      this.isDesktop = PanelBreakpointInstance.isDesktop();
      this.containerWidth = this.readContainerWidth();
      this.updateLayoutMode();
      this.clampDragWidth();

      if (this.dragWidth == null) {
        this.defaultPanelWidthPx = this.readPanelWidth();
      }
    },
  },
};
</script>

<template>
  <section v-if="showResizer" :aria-labelledby="handleId">
    <accessible-panel-resizer
      :id="handleId"
      v-model="dragWidth"
      :default-size="defaultPanelWidthPx"
      :min-size="$options.MIN_PANEL_PX"
      :max-size="computedMaxPx"
      :side="side"
      :class="handleClasses"
      :aria-label="resizeLabel"
    />
  </section>
</template>
