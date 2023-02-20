import { GlBreakpointInstance as bp, breakpoints } from '@gitlab/ui/dist/utils';
import { debounce } from 'lodash';
import { setCookie, getCookie } from '~/lib/utils/common_utils';

export const SIDEBAR_COLLAPSED_CLASS = 'page-with-super-sidebar-collapsed';
export const SIDEBAR_COLLAPSED_COOKIE = 'super_sidebar_collapsed';
export const SIDEBAR_COLLAPSED_COOKIE_EXPIRATION = 365 * 10;

export const findPage = () => document.querySelector('.page-with-super-sidebar');
export const findToggle = () => document.querySelector('.js-super-sidebar-toggle');

const isCollapsed = () => findPage().classList.contains(SIDEBAR_COLLAPSED_CLASS);

// See documentation: https://design.gitlab.com/patterns/navigation#left-sidebar
// NOTE: at 1200px nav sidebar should not overlap the content
// https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/24555#note_134136110
export const isDesktopBreakpoint = () => bp.windowWidth() >= breakpoints.xl;

export const getCollapsedCookie = () => getCookie(SIDEBAR_COLLAPSED_COOKIE) === 'true';

export const toggleSuperSidebarCollapsed = (collapsed, saveCookie) => {
  findPage().classList.toggle(SIDEBAR_COLLAPSED_CLASS, collapsed);

  if (saveCookie && isDesktopBreakpoint()) {
    setCookie(SIDEBAR_COLLAPSED_COOKIE, collapsed, {
      expires: SIDEBAR_COLLAPSED_COOKIE_EXPIRATION,
    });
  }
};

export const initSuperSidebarCollapsedState = () => {
  const collapsed = isDesktopBreakpoint() ? getCollapsedCookie() : true;
  toggleSuperSidebarCollapsed(collapsed, false);
};

export const bindSuperSidebarCollapsedEvents = () => {
  if (findToggle()) {
    findToggle().addEventListener('click', () => {
      const value = !isCollapsed();
      toggleSuperSidebarCollapsed(value, true);
    });
  }

  window.addEventListener('resize', debounce(initSuperSidebarCollapsedState, 100));
};
