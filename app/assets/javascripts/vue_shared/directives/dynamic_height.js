import { DynamicHeightManager } from '~/vue_shared/utils/dynamic_height';

/**
 * v-dynamic-height directive
 *
 * Automatically calculates and sets the height of an element based on available viewport space.
 * The height is calculated as max(calc(100vh - contentHeight), 500px) where contentHeight
 * is the difference between the closest container's height and the element's current height.
 *
 * Usage:
 * ```
 * <div v-dynamic-height></div>
 * <div v-dynamic-height="{ closest: '.content-wrapper' }"></div>
 * <div v-dynamic-height="{ closest: '.content-wrapper', minHeight: 300 }"></div>
 * ```
 *
 * Options:
 * - closest: CSS selector for the container element to measure against (default: '.content-wrapper')
 * - minHeight: Minimum height in pixels (default: 500)
 * - debounce: Debounce time for resize events in milliseconds (default: CONTENT_UPDATE_DEBOUNCE)
 */

const DYNAMIC_HEIGHT_KEY = 'GL_DYNAMIC_HEIGHT';

const initDynamicHeight = (el, binding) => {
  if (el[DYNAMIC_HEIGHT_KEY]) return;

  const options = typeof binding.value === 'object' ? binding.value : {};
  const manager = new DynamicHeightManager(el, options);
  manager.init();

  // Store manager reference on the element for cleanup
  el[DYNAMIC_HEIGHT_KEY] = manager;
};

const updateDynamicHeight = (el, binding) => {
  if (!el[DYNAMIC_HEIGHT_KEY]) return;

  const options = typeof binding.value === 'object' ? binding.value : {};
  el[DYNAMIC_HEIGHT_KEY].updateOptions(options);
};

const cleanupDynamicHeight = (el) => {
  if (!el[DYNAMIC_HEIGHT_KEY]) return;

  el[DYNAMIC_HEIGHT_KEY].destroy();
  el[DYNAMIC_HEIGHT_KEY] = null;
};

export default {
  inserted(el, binding) {
    initDynamicHeight(el, binding);
  },

  componentUpdated(el, binding) {
    updateDynamicHeight(el, binding);
  },

  unbind(el) {
    cleanupDynamicHeight(el);
  },
};
