<script>
import { debounce } from 'lodash';
import { mapState } from 'pinia';
import { contentTop } from '~/lib/utils/common_utils';
import { useBatchComments } from '~/batch_comments/store';

const MAX_ITEMS_ON_NARROW_SCREEN = 8;
// Should be enough for the very long titles (10+ lines) on the max smallest screen
const MAX_SCROLL_Y = 600;
const BOTTOM_OFFSET = 16;

export default {
  name: 'TreeListHeight',
  props: {
    itemsCount: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      scrollerHeight: 0,
      rowHeight: 0,
      reviewBarHeight: 0,
      scrollY: 0,
      isNarrowScreen: false,
      mediaQueryMatch: null,
    };
  },
  computed: {
    ...mapState(useBatchComments, ['reviewBarRendered', 'draftsCount']),
    reviewBarEnabled() {
      return this.draftsCount > 0;
    },
    debouncedHeightCalc() {
      return debounce(this.calculateScrollerHeight, 100);
    },
    debouncedRecordScroll() {
      return debounce(this.recordScroll, 50);
    },
  },
  watch: {
    reviewBarRendered: {
      handler(rendered) {
        if (!rendered || this.reviewBarHeight) return;
        this.reviewBarHeight = document.querySelector('.js-review-bar').offsetHeight;
        this.debouncedHeightCalc();
      },
      immediate: true,
    },
    reviewBarEnabled: 'debouncedHeightCalc',
    scrollY: 'debouncedHeightCalc',
    isNarrowScreen: 'recordScroll',
  },
  mounted() {
    const computedStyles = getComputedStyle(this.$refs.scrollRoot);
    this.rowHeight = parseInt(computedStyles.getPropertyValue('--file-row-height'), 10);

    const largeBreakpointSize = parseInt(computedStyles.getPropertyValue('--breakpoint-lg'), 10);
    this.mediaQueryMatch = window.matchMedia(`(max-width: ${largeBreakpointSize - 1}px)`);
    this.isNarrowScreen = this.mediaQueryMatch.matches;
    this.mediaQueryMatch.addEventListener('change', this.handleMediaMatch);

    window.addEventListener('resize', this.debouncedHeightCalc, { passive: true });
    window.addEventListener('scroll', this.debouncedRecordScroll, { passive: true });
    window.mrTabs.eventHub.$on('MergeRequestTabChange', this.onTabChange);

    this.calculateScrollerHeight();
  },
  beforeDestroy() {
    this.mediaQueryMatch.removeEventListener('change', this.handleMediaMatch);
    this.mediaQueryMatch = null;
    window.removeEventListener('resize', this.debouncedHeightCalc, { passive: true });
    window.removeEventListener('scroll', this.debouncedRecordScroll, { passive: true });
    window.mrTabs.eventHub.$off('MergeRequestTabChange', this.onTabChange);
  },
  methods: {
    recordScroll() {
      const { scrollY } = window;
      if (scrollY > MAX_SCROLL_Y || this.isNarrowScreen) {
        this.scrollY = MAX_SCROLL_Y;
      } else {
        this.scrollY = window.scrollY;
      }
    },
    handleMediaMatch({ matches }) {
      this.isNarrowScreen = matches;
    },
    calculateScrollerHeight() {
      if (this.isNarrowScreen) {
        const maxItems = Math.min(MAX_ITEMS_ON_NARROW_SCREEN, this.itemsCount);
        const maxHeight = maxItems * this.rowHeight;
        this.scrollerHeight = Math.min(maxHeight, window.innerHeight - contentTop());
      } else {
        const { y } = this.$refs.scrollRoot.getBoundingClientRect();
        const reviewBarOffset = this.reviewBarEnabled ? this.reviewBarHeight : 0;
        // distance from element's top vertical position in the viewport to the bottom of the viewport minus offsets
        this.scrollerHeight = window.innerHeight - y - reviewBarOffset - BOTTOM_OFFSET;
      }
    },
    onTabChange(currentTab) {
      if (currentTab !== 'diffs') return;
      this.debouncedHeightCalc();
    },
  },
};
</script>

<template>
  <div ref="scrollRoot">
    <slot :scroller-height="scrollerHeight" :row-height="rowHeight"></slot>
  </div>
</template>
