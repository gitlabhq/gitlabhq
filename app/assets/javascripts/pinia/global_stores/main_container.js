import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { PanelBreakpointInstance } from '~/panel_breakpoint_instance';

/**
 * Main container store for container-based responsive breakpoint detection
 *
 * Provides semantic container size detection based on Pajamas breakpoints:
 * - Compact: < 768px (xs + sm breakpoints combined)
 * - Intermediate: 768px - 1199px (md + lg breakpoints combined)
 * - Wide: >= 1200px (xl breakpoint)
 */
export const useMainContainer = defineStore('mainContainerStore', () => {
  const currentBreakpoint = ref(PanelBreakpointInstance.getBreakpointSize());

  const isCompact = computed(() => ['xs', 'sm'].includes(currentBreakpoint.value));
  const isIntermediate = computed(() => ['md', 'lg'].includes(currentBreakpoint.value));
  const isWide = computed(() => currentBreakpoint.value === 'xl');

  const update = () => {
    currentBreakpoint.value = PanelBreakpointInstance.getBreakpointSize();
  };

  PanelBreakpointInstance.addResizeListener(update);

  return {
    isCompact,
    isIntermediate,
    isWide,
  };
});
