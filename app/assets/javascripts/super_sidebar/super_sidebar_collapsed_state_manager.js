import { debounce } from 'lodash';
import { GlBreakpointInstance, breakpoints } from '@gitlab/ui/src/utils'; // eslint-disable-line no-restricted-syntax -- GlBreakpointInstance is used intentionally here. In this case we must obtain viewport breakpoints
import { setCookie, getCookie } from '~/lib/utils/common_utils';
import { sidebarState } from './constants';

export const SIDEBAR_COLLAPSED_CLASS = 'page-with-super-sidebar-collapsed';
export const SIDEBAR_BLOCKED_CSS_TRANSITIONS_CLASS = 'super-sidebar-has-css-transitions-blocked';
export const SIDEBAR_COLLAPSED_COOKIE = 'super_sidebar_collapsed';
export const SIDEBAR_COLLAPSED_COOKIE_EXPIRATION = 365 * 10;
export const SIDEBAR_TRANSITION_DURATION = 200;

export const findPage = () => document.querySelector('.page-with-super-sidebar');
export const findSidebar = () => document.querySelector('.super-sidebar');

export const isCollapsed = () => findPage().classList.contains(SIDEBAR_COLLAPSED_CLASS);

// See documentation: https://design.gitlab.com/patterns/navigation#left-sidebar
// NOTE: at 1200px nav sidebar should not overlap the content
// https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/24555#note_134136110
export const isDesktopBreakpoint = () => GlBreakpointInstance.windowWidth() >= breakpoints.xl;

export const getCollapsedCookie = () => getCookie(SIDEBAR_COLLAPSED_COOKIE) === 'true';

export const toggleSuperSidebarCollapsed = (collapsed) => {
  findPage().classList.toggle(SIDEBAR_COLLAPSED_CLASS, collapsed);

  sidebarState.isPeek = false;
  sidebarState.isPeekable = collapsed;
  sidebarState.hasPeeked = false;
  sidebarState.isHoverPeek = false;
  sidebarState.wasHoverPeek = false;
  sidebarState.isCollapsed = collapsed;
  sidebarState.isMobile = !isDesktopBreakpoint();
};

export const toggleSuperSidebarIconOnly = (iconOnly = !sidebarState.isIconOnly) => {
  sidebarState.isIconOnly = iconOnly;

  setCookie(SIDEBAR_COLLAPSED_COOKIE, iconOnly, {
    expires: SIDEBAR_COLLAPSED_COOKIE_EXPIRATION,
  });
};

export const initSuperSidebarCollapsedState = () => {
  let collapsed = true;
  if (isDesktopBreakpoint()) {
    // The left sidebar can never be fully collapsed on desktop.
    collapsed = false;
  }

  toggleSuperSidebarCollapsed(collapsed);

  // This cookie means "collapsed to icon-only"
  toggleSuperSidebarIconOnly(getCollapsedCookie());
};

export const bindSuperSidebarCollapsedEvents = () => {
  let previousWindowWidth = window.innerWidth;

  // We defer the removal of the class to prevent some CSS transitions from kicking in right when
  // the window gets resised.
  const reEnableCSSTransitions = debounce(() => {
    findPage().classList.remove(SIDEBAR_BLOCKED_CSS_TRANSITIONS_CLASS);
  }, SIDEBAR_TRANSITION_DURATION);

  const checkWindowWidthChanged = debounce(() => {
    reEnableCSSTransitions();

    const newWindowWidth = window.innerWidth;
    const widthChanged = previousWindowWidth !== newWindowWidth;

    if (widthChanged) {
      initSuperSidebarCollapsedState();
    }
    previousWindowWidth = newWindowWidth;
  }, 100);

  const callback = () => {
    // We add this class while the window is being resized so that we can disable some CSS
    // transitions while the window is being resized.
    findPage().classList.add(SIDEBAR_BLOCKED_CSS_TRANSITIONS_CLASS);
    checkWindowWidthChanged();
  };

  window.addEventListener('resize', callback);

  return () => window.removeEventListener('resize', callback);
};
