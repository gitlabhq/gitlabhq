import Tracking from '~/tracking';
import { MAX_ITEM_LENGTH } from './data';

export const TRACKING_CATEGORY = 'Language filters';
export const TRACKING_LABEL_FILTERS = 'Filters';

export const TRACKING_LABEL_MAX = 'Max Shown';
export const TRACKING_LABEL_SHOW_MORE = 'Show More';
export const TRACKING_LABEL_APPLY = 'Apply Filters';
export const TRACKING_LABEL_RESET = 'Reset Filters';
export const TRACKING_LABEL_ALL = 'All Filters';
export const TRACKING_PROPERTY_MAX = `More than ${MAX_ITEM_LENGTH} filters to show`;

export const TRACKING_ACTION_CLICK = 'search:agreggations:language:click';
export const TRACKING_ACTION_SHOW = 'search:agreggations:language:show';

// select is imported and used in checkbox_filter.vue
export const TRACKING_ACTION_SELECT = 'search:agreggations:language:select';

export const trackShowMore = () =>
  Tracking.event(TRACKING_ACTION_CLICK, TRACKING_LABEL_SHOW_MORE, {
    label: TRACKING_LABEL_ALL,
  });

export const trackShowHasOverMax = () =>
  Tracking.event(TRACKING_ACTION_SHOW, TRACKING_LABEL_FILTERS, {
    label: TRACKING_LABEL_MAX,
    property: TRACKING_PROPERTY_MAX,
  });

export const trackSubmitQuery = () =>
  Tracking.event(TRACKING_ACTION_CLICK, TRACKING_LABEL_APPLY, {
    label: TRACKING_CATEGORY,
  });

export const trackResetQuery = () =>
  Tracking.event(TRACKING_ACTION_CLICK, TRACKING_LABEL_RESET, {
    label: TRACKING_CATEGORY,
  });
