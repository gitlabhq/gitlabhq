// Note: all constants defined here are considered internal implementation
// details for the sidebar. They should not be imported by anything outside of
// the super_sidebar directory.

export const SETTINGS_DISCLOSURE_PORTAL_NAME = 'super-sidebar-settings-disclosure';
export const SETTINGS_MENU_ITEM_ID = 'settings_menu';

// Shared default for the pin context injected/passed into nav items.
export const DEFAULT_PIN_CONTEXT = {
  pinnedItemIds: { ids: [] },
  panelSupportsPins: false,
  panelType: '',
};

export const JS_TOGGLE_EXPAND_CLASS = 'js-super-sidebar-toggle-expand';

export const TRACKING_UNKNOWN_ID = 'item_without_id';
export const TRACKING_UNKNOWN_PANEL = 'nav_panel_unknown';
export const CLICK_MENU_ITEM_ACTION = 'click_menu_item';
export const CLICK_PINNED_MENU_ITEM_ACTION = 'click_pinned_menu_item';

export const PANEL_TYPES = {
  GROUP: 'group',
  PROJECT: 'project',
  ORGANIZATION: 'organization',
  ORGANIZATION_ADMIN: 'organization_admin',
  YOUR_WORK: 'your_work',
};

export const PANELS_WITH_PINS = [PANEL_TYPES.GROUP, PANEL_TYPES.PROJECT, PANEL_TYPES.ORGANIZATION];

// Panels where the flag can hide unpinned items and the sidebar customization
// control applies. Excludes organization, which keeps the full category list.
export const PANELS_WITH_HIDEABLE_UNPINNED_ITEMS = PANELS_WITH_PINS.filter(
  (panelType) => panelType !== PANEL_TYPES.ORGANIZATION,
);

// Marks nav items the backend still emits but the sidebar must not show (e.g.
// duplicate "Work items" entries). Every place that lists nav items has to
// filter these out.
export const HIDDEN_NAV_ITEM_CLASS = 'js-super-sidebar-nav-item-hidden';

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

// Groups persist as a { [key]: boolean } map in local storage rather than
// cookies, which the server never reads.
export const SIDEBAR_PINNED_GROUPS_EXPANDED_STORAGE_KEY = 'super-sidebar-pinned-groups-expanded';

export const PINNED_NAV_STORAGE_KEY = 'super-sidebar-pinned-nav-item-clicked';

// The three mutually-exclusive ways the pinnable sidebar can present its
// navigation while hide_unpinned_sidebar_items is enabled.
export const SIDEBAR_NAV_MODE_PINNED_ONLY = 'pinned_only';
export const SIDEBAR_NAV_MODE_ALL_CATEGORIES = 'all_categories';
export const SIDEBAR_NAV_MODE_GROUPED_PINS = 'grouped_pins';

export const SIDEBAR_NAV_MODES = [
  SIDEBAR_NAV_MODE_PINNED_ONLY,
  SIDEBAR_NAV_MODE_ALL_CATEGORIES,
  SIDEBAR_NAV_MODE_GROUPED_PINS,
];

// Remembers the user's chosen navigation mode (one of SIDEBAR_NAV_MODE_*).
export const SIDEBAR_NAV_MODE_STORAGE_KEY = 'super-sidebar-nav-mode';

// Frequent items constants
export const FREQUENT_ITEMS = {
  MAX_COUNT: 20,
  ELIGIBLE_FREQUENCY: 3,
};

export const FIFTEEN_MINUTES_IN_MS = 900000;

export const STORAGE_KEY = {
  projects: 'frequent-projects',
  groups: 'frequent-groups',
};

export const CONTEXT_NAMESPACE_GROUPS = 'groups';

export const MAX_OPEN_WORK_ITEMS_COUNT = 10000;
