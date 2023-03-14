export const BYTES_IN_KIB = 1024;
export const DEFAULT_DEBOUNCE_AND_THROTTLE_MS = 250;
export const THOUSAND = 1000;
export const TRUNCATE_WIDTH_DEFAULT_WIDTH = 80;
export const TRUNCATE_WIDTH_DEFAULT_FONT_SIZE = 12;

export const DATETIME_RANGE_TYPES = {
  fixed: 'fixed',
  anchored: 'anchored',
  rolling: 'rolling',
  open: 'open',
  invalid: 'invalid',
};

export const BV_SHOW_MODAL = 'bv::show::modal';
export const BV_HIDE_MODAL = 'bv::hide::modal';
export const BV_HIDE_TOOLTIP = 'bv::hide::tooltip';
export const BV_DROPDOWN_SHOW = 'bv::dropdown::show';
export const BV_DROPDOWN_HIDE = 'bv::dropdown::hide';

export const DEFAULT_TH_CLASSES =
  'gl-bg-transparent! gl-border-b-solid! gl-border-b-gray-100! gl-p-5! gl-border-b-1!';

// We set the drawer's z-index to 252 to clear flash messages that might
// be displayed in the page and that have a z-index of 251.
export const DRAWER_Z_INDEX = 252;

export const MIN_USERNAME_LENGTH = 2;

export const BYTES_FORMAT_BYTES = 'Bytes';
export const BYTES_FORMAT_KIB = 'KiB';
export const BYTES_FORMAT_MIB = 'MiB';
export const BYTES_FORMAT_GIB = 'GiB';
