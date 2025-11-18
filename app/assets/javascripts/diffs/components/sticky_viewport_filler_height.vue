<script>
import { throttle } from 'lodash';
import { observeElementOnce } from '~/lib/utils/dom_utils';
import { getScrollingElement } from '~/lib/utils/scroll_utils';

/*
 * This is a universal performant component to fill in all the available height in viewport for sticky elements.
 * It supports:
 *   1. Scrolling into element and updating the height so it doesn't go over what can be visible in a viewport
 *   2. Maintaining element height when it's stuck and all the height is consumed
 *   3. Scrolling outside the element when we scroll to the parent element's end, height will be shrunk
 *   4. Reacting to element appearance/disappearance:
 *        * each time the element appears it properly updates its height
 *        * nothing is updated when element is not visible
 *   5. Reacting to window resize, height is updated
 *  */
export default {
  name: 'StickyViewportFillerHeight',
  props: {
    stickyTopOffset: {
      type: Number,
      required: false,
      default: 0,
    },
    stickyBottomOffset: {
      type: Number,
      required: false,
      default: 0,
    },
    minHeight: {
      type: Number,
      required: false,
      default: 0,
    },
    samplingRate: {
      type: Number,
      required: false,
      // 6ms is enough to target 120fps
      default: 6,
    },
  },
  data() {
    return {
      viewport: null,
      viewportHeight: 0,
      viewportTopOffset: 0,
      visible: false,
      currentTop: 0,
      parentRect: { bottom: 0, height: 0 },
      rootObserver: null,
      parentObserver: null,
    };
  },
  computed: {
    parent() {
      return this.$refs.root.parentElement;
    },
    throttledSampleRects() {
      return throttle(this.sampleRects, this.samplingRate, { leading: true });
    },
    endReached() {
      return this.viewportHeight > this.parentRect.bottom;
    },
    topOffset() {
      return this.currentTop - this.viewportTopOffset;
    },
    availableHeight() {
      // parent is fully scrolled, the sticky element is pushed from both top and bottom
      if (this.endReached) {
        return this.parentRect.bottom - Math.max(this.topOffset, this.stickyTopOffset);
      }
      return this.viewportHeight - this.topOffset - this.stickyBottomOffset;
    },
    height() {
      const maxHeight = this.viewportHeight - this.stickyTopOffset - this.stickyBottomOffset;
      return `${Math.min(maxHeight, Math.max(this.minHeight, this.availableHeight))}px`;
    },
  },
  watch: {
    visible(isVisible) {
      if (isVisible) {
        this.sampleRects();
        this.observerParentResize();
        this.observeViewportChanges();
      } else {
        this.disconnectParent();
        this.disconnectViewport();
      }
    },
  },
  mounted() {
    this.setViewport();
    this.observeRootVisibility();
    this.cacheViewportHeight();
  },
  beforeDestroy() {
    this.disconnectRoot();
    this.disconnectParent();
    this.disconnectViewport();
  },
  methods: {
    setViewport() {
      const initialViewport = getScrollingElement(this.$refs.root);
      if (initialViewport === document.scrollingElement) {
        this.viewport = window;
      } else {
        this.viewport = initialViewport;
        this.viewportTopOffset = this.viewport.getBoundingClientRect().top;
      }
    },
    cacheViewportHeight() {
      this.viewportHeight = this.viewport.offsetHeight || this.viewport.innerHeight;
    },
    sampleRects() {
      observeElementOnce(this.$refs.root, ([root]) => {
        this.currentTop = root.boundingClientRect.top;
      });
      observeElementOnce(this.parent, ([parent]) => {
        const { bottom, height } = parent.boundingClientRect;
        this.parentRect = { bottom, height };
      });
    },
    observeRootVisibility() {
      this.rootObserver = new IntersectionObserver(([root]) => {
        this.visible = root.isIntersecting;
      });
      this.rootObserver.observe(this.$refs.root);
    },
    observerParentResize() {
      // parent could grow, we might no longer be at the bottom of the parent element
      this.parentObserver = new ResizeObserver(throttle(this.sampleRects, 20));
      this.parentObserver.observe(this.parent);
    },
    observeViewportChanges() {
      this.viewport.addEventListener('scroll', this.throttledSampleRects, {
        passive: true,
      });
      window.addEventListener('resize', this.cacheViewportHeight, { passive: true });
    },
    disconnectRoot() {
      if (!this.rootObserver) return;
      this.rootObserver.disconnect();
      this.rootObserver = null;
    },
    disconnectParent() {
      if (!this.parentObserver) return;
      this.parentObserver.disconnect();
      this.parentObserver = null;
    },
    disconnectViewport() {
      this.throttledSampleRects.cancel();
      this.viewport.removeEventListener('scroll', this.throttledSampleRects);
      window.removeEventListener('resize', this.cacheViewportHeight);
    },
  },
};
</script>

<template>
  <div ref="root" :style="{ height }">
    <slot></slot>
  </div>
</template>
