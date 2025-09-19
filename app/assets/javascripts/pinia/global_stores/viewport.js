import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { getPageBreakpoints } from '~/lib/utils/css_utils';

/**
 * Viewport store for responsive breakpoint detection
 *
 * Provides semantic viewport size detection based on Pajamas breakpoints:
 * - Compact: < 768px (xs + sm breakpoints combined)
 * - Intermediate: 768px - 1199px (md + lg breakpoints combined)
 * - Wide: >= 1200px (xl breakpoint)
 */

export const useViewport = defineStore('viewportStore', () => {
  const isCompactSize = ref(false);
  const isIntermediateSize = ref(false);
  const isWideSize = ref(false);
  const isNarrowScreen = ref(false);

  const registerBreakpoint = (breakpointConfig) => {
    const [mediaQuery, stateRef] = breakpointConfig;
    stateRef.value = mediaQuery.matches;
    mediaQuery.addEventListener('change', ({ matches }) => {
      stateRef.value = matches;
    });
  };

  const breakpoints = getPageBreakpoints();
  [
    [breakpoints.compact, isCompactSize],
    [breakpoints.intermediate, isIntermediateSize],
    [breakpoints.wide, isWideSize],
    [breakpoints.narrow, isNarrowScreen],
  ].forEach(registerBreakpoint);

  const setViewportState = (state) => {
    if (state.isNarrowScreen !== undefined) {
      isNarrowScreen.value = state.isNarrowScreen;
    }
    if (state.isCompactSize !== undefined) {
      isCompactSize.value = state.isCompactSize;
    }
    if (state.isIntermediateSize !== undefined) {
      isIntermediateSize.value = state.isIntermediateSize;
    }
    if (state.isWideSize !== undefined) {
      isWideSize.value = state.isWideSize;
    }
  };

  const reset = () => {
    isCompactSize.value = false;
    isIntermediateSize.value = false;
    isWideSize.value = false;
    isNarrowScreen.value = false;
  };

  return {
    // used only for testing
    setViewportState,
    // used only for testing
    reset,

    isNarrowScreen: computed(() => isNarrowScreen.value),

    isCompactSize: computed(() => isCompactSize.value),
    isIntermediateSize: computed(() => isIntermediateSize.value),
    isWideSize: computed(() => isWideSize.value),
  };
});
