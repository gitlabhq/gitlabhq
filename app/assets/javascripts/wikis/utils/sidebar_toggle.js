/**
 * Get the Wiki sidebar element
 *
 * @returns {HTMLElement|null} The sidebar element or null if not found
 */
export function getSidebarEl() {
  return document.querySelector('.js-wiki-sidebar');
}

/**
 * Toggle the Wiki sidebar open/closed state
 *
 * This utility is used by both WikiHeader (open button) and WikiSidebarHeader (close button)
 * to maintain consistent sidebar toggle behavior across components.
 *
 * Note: This uses localStorage key 'wiki-sidebar-open' to persist the sidebar's expanded/collapsed state.
 * This is separate from 'wiki-sidebar-expanded' which controls the pages list visibility within the sidebar.
 *
 * @param {boolean} persistSetting - Whether to save the state to localStorage (default: true)
 */
export function toggleWikiSidebar(persistSetting = true) {
  const sidebarEl = getSidebarEl();
  if (!sidebarEl) return;

  const isExpanded = sidebarEl.classList.contains('sidebar-expanded');

  if (isExpanded) {
    sidebarEl.classList.add('sidebar-collapsed');
    sidebarEl.classList.remove('sidebar-expanded');
    if (persistSetting) localStorage.setItem('wiki-sidebar-open', 'false');
  } else {
    sidebarEl.classList.remove('sidebar-collapsed');
    sidebarEl.classList.add('sidebar-expanded');
    if (persistSetting) localStorage.setItem('wiki-sidebar-open', 'true');
  }
}
