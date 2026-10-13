import {
  WIKI_SIDEBAR_WIDTH_CSS_VAR,
  WIKI_SIDEBAR_WIDTH_STORAGE_KEY,
  WIKI_SIDEBAR_DEFAULT_WIDTH,
} from '~/wikis/constants';

/**
 * Get the Wiki sidebar element
 *
 * @returns {HTMLElement|null} The sidebar element or null if not found
 */
export function getSidebarEl() {
  return document.querySelector('.js-wiki-sidebar');
}

/**
 * Get the Wiki overview element that owns the --wiki-sidebar-width CSS variable
 *
 * @returns {HTMLElement|null} The overview element or null if not found
 */
export function getWikiOverviewEl() {
  return document.querySelector('.js-wiki-overview');
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
  const overviewEl = getWikiOverviewEl();

  if (isExpanded) {
    sidebarEl.classList.add('sidebar-collapsed');
    sidebarEl.classList.remove('sidebar-expanded');
    // Zero the shared width variable so consumers (e.g. the sticky header) collapse in sync
    overviewEl?.style.setProperty(WIKI_SIDEBAR_WIDTH_CSS_VAR, '0px');
    if (persistSetting) localStorage.setItem('wiki-sidebar-open', 'false');
  } else {
    sidebarEl.classList.remove('sidebar-collapsed');
    sidebarEl.classList.add('sidebar-expanded');
    // Restore the width variable to the resizer's persisted value (or the default)
    const storedWidth = Number(localStorage.getItem(WIKI_SIDEBAR_WIDTH_STORAGE_KEY));
    const restoredWidth =
      Number.isFinite(storedWidth) && storedWidth > 0 ? storedWidth : WIKI_SIDEBAR_DEFAULT_WIDTH;
    overviewEl?.style.setProperty(WIKI_SIDEBAR_WIDTH_CSS_VAR, `${restoredWidth}px`);
    if (persistSetting) localStorage.setItem('wiki-sidebar-open', 'true');
  }
}
