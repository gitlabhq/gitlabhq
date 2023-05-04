import { GlBreakpointInstance as bp, breakpoints } from '@gitlab/ui/dist/utils';
import { debounce } from 'lodash';
import { setCookie, getCookie } from '~/lib/utils/common_utils';
import { sidebarState } from './constants';

export const SIDEBAR_COLLAPSED_CLASS = 'page-with-super-sidebar-collapsed';
export const SIDEBAR_COLLAPSED_COOKIE = 'super_sidebar_collapsed';
export const SIDEBAR_COLLAPSED_COOKIE_EXPIRATION = 365 * 10;
export const SIDEBAR_TRANSITION_DURATION = 200;

export const findPage = () => document.querySelector('.page-with-super-sidebar');
export const findSidebar = () => document.querySelector('.super-sidebar');

export const isCollapsed = () => findPage().classList.contains(SIDEBAR_COLLAPSED_CLASS);

// See documentation: https://design.gitlab.com/patterns/navigation#left-sidebar
// NOTE: at 1200px nav sidebar should not overlap the content
// https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/24555#note_134136110
export const isDesktopBreakpoint = () => bp.windowWidth() >= breakpoints.xl;

export const getCollapsedCookie = () => getCookie(SIDEBAR_COLLAPSED_COOKIE) === 'true';

export const toggleSuperSidebarCollapsed = (collapsed, saveCookie) => {
  findPage().classList.toggle(SIDEBAR_COLLAPSED_CLASS, collapsed);

  sidebarState.isPeek = false;
  sidebarState.isPeekable = Boolean(gon.features?.superSidebarPeek) && collapsed;
  sidebarState.isCollapsed = collapsed;

  if (saveCookie && isDesktopBreakpoint()) {
    setCookie(SIDEBAR_COLLAPSED_COOKIE, collapsed, {
      expires: SIDEBAR_COLLAPSED_COOKIE_EXPIRATION,
    });
  }
};

export const initSuperSidebarCollapsedState = (forceDesktopExpandedSidebar = false) => {
  let collapsed = true;
  if (isDesktopBreakpoint()) {
    collapsed = forceDesktopExpandedSidebar ? false : getCollapsedCookie();
  }
  toggleSuperSidebarCollapsed(collapsed, false);
};

export const bindSuperSidebarCollapsedEvents = (forceDesktopExpandedSidebar = false) => {
  let previousWindowWidth = window.innerWidth;

  const callback = debounce(() => {
    const newWindowWidth = window.innerWidth;
    const widthChanged = previousWindowWidth !== newWindowWidth;

    if (widthChanged) {
      initSuperSidebarCollapsedState(forceDesktopExpandedSidebar);
    }
    previousWindowWidth = newWindowWidth;
  }, 100);

  window.addEventListener('resize', callback);

  return () => window.removeEventListener('resize', callback);
};
