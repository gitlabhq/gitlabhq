/**
 * Check if user prefers reduced motion, return 'auto' if true, otherwise return 'smooth'.
 * This helps support accessibility preferences for users who experience motion sickness.
 */
export function scrollBehavior() {
  return window.matchMedia(`(prefers-reduced-motion: reduce)`).matches ? 'auto' : 'smooth';
}

/**
 * Scrolls with smooth behavior, respecting user's motion preferences.
 * @param {ScrollToOptions} [options] - Additional scroll options
 */
export function smoothScrollTo(options) {
  const behavior = scrollBehavior();

  // eslint-disable-next-line no-restricted-properties -- we should remove this method and move to `scrollTo`.
  window.scrollTo({ ...options, behavior });
}

/**
 * Scrolls to the top of the page with smooth behavior, respecting user's motion preferences.
 */
export function smoothScrollTop() {
  smoothScrollTo({ top: 0 });
}
