/**
 * Utility for handling debounced visibility changes on the homepage
 * Prevents excessive reloads when users quickly switch between tabs
 *
 * The first visibility change sets a timestamp but does not trigger a reload.
 * Subsequent visibility changes only trigger reloads if enough time has passed
 * since the last reload (debounce period).
 */

// Default debounce time: 5 seconds
const DEFAULT_DEBOUNCE_TIME = 5 * 1000;

/**
 * Creates a debounced visibility change handler
 * @param {Function} reloadFunction - Function to call when reload should happen
 * @param {number} debounceTime - Time in milliseconds to debounce (default: 5000)
 * @returns {Function} Debounced handler function
 */
export function createDebouncedVisibilityHandler(
  reloadFunction,
  debounceTime = DEFAULT_DEBOUNCE_TIME,
) {
  let lastReloadTime = null;

  return function handleVisibilityChange() {
    if (document.hidden) {
      return;
    }

    const now = Date.now();

    // If this is the first time, just set the time without reloading
    if (!lastReloadTime) {
      lastReloadTime = now;
      return;
    }

    // Only reload if enough time has passed since last reload
    if (now - lastReloadTime >= debounceTime) {
      lastReloadTime = now;
      reloadFunction();
    }
  };
}
