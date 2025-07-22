/**
 * Detects if the current device has touch capability
 *
 * @returns {boolean} True if device has touch capability, false otherwise
 */
export function hasTouchCapability() {
  return Boolean(
    'ontouchstart' in window ||
      navigator.maxTouchPoints > 0 ||
      navigator.msMaxTouchPoints > 0 ||
      (typeof window.DocumentTouch !== 'undefined' && document instanceof window.DocumentTouch),
  );
}
