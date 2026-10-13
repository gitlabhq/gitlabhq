import { observable } from '~/lib/utils/observable';

export const sidebarState = observable('super_sidebar_state', {
  isCollapsed: false,
  isMobile: false,
  isIconOnly: false,
});
