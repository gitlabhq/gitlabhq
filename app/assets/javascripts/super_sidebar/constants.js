// Note: all constants defined here are considered internal implementation
// details for the sidebar. They should not be imported by anything outside of
// the super_sidebar directory.

import Vue from 'vue';

export const SIDEBAR_PORTAL_ID = 'sidebar-portal-mount';
export const JS_TOGGLE_COLLAPSE_CLASS = 'js-super-sidebar-toggle-collapse';
export const JS_TOGGLE_EXPAND_CLASS = 'js-super-sidebar-toggle-expand';

export const portalState = Vue.observable({
  ready: false,
});

export const sidebarState = Vue.observable({
  contextSwitcherOpen: false,
  isCollapsed: false,
  isPeek: false,
  openPeekTimer: null,
  closePeekTimer: null,
});

export const helpCenterState = Vue.observable({
  showTanukiBotChatDrawer: false,
});

export const MAX_FREQUENT_PROJECTS_COUNT = 5;
export const MAX_FREQUENT_GROUPS_COUNT = 3;

export const SUPER_SIDEBAR_PEEK_OPEN_DELAY = 200;
export const SUPER_SIDEBAR_PEEK_CLOSE_DELAY = 500;

export const TRACKING_UNKNOWN_ID = 'item_without_id';
export const TRACKING_UNKNOWN_PANEL = 'nav_panel_unknown';
export const CLICK_MENU_ITEM_ACTION = 'click_menu_item';

export const PANELS_WITH_PINS = ['group', 'project'];

export const USER_MENU_TRACKING_DEFAULTS = {
  'data-track-property': 'nav_user_menu',
  'data-track-action': 'click_link',
};

export const HELP_MENU_TRACKING_DEFAULTS = {
  'data-track-property': 'nav_help_menu',
  'data-track-action': 'click_link',
};

export const SIDEBAR_PINS_EXPANDED_COOKIE = 'sidebar_pinned_section_expanded';
export const SIDEBAR_COOKIE_EXPIRATION = 365 * 10;

export const DROPDOWN_Y_OFFSET = 4;
