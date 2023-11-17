/**
 * This triggers a re-fetch of the user counts
 *
 * It is separate from the user_counts_manager, so that
 * this function is side-effect free and can be used in
 * anywhere in the app without bloating bundle size
 */
export function fetchUserCounts() {
  document.dispatchEvent(new CustomEvent('userCounts:fetch'));
}
