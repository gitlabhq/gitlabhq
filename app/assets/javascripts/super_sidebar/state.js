import { observable } from '~/lib/utils/observable';

export const portalState = observable('super_sidebar_portal_state', {
  ready: false,
});

export const sidebarState = observable('super_sidebar_state', {
  isCollapsed: false,
  isMobile: false,
  isIconOnly: false,
});
