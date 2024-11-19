import Tracking from '~/tracking';
import { LANGUAGE_DEFAULT_ITEM_LENGTH } from '../../constants';

export const TRACKING_CATEGORY = 'Language filters';
export const TRACKING_LABEL_FILTERS = 'Filters';

export const TRACKING_LABEL_MAX = 'Max Shown';
export const TRACKING_LABEL_SHOW_MORE = 'Show More';
export const TRACKING_LABEL_APPLY = 'Apply Filters';
export const TRACKING_LABEL_RESET = 'Reset Filters';
export const TRACKING_LABEL_ALL = 'All Filters';
export const TRACKING_PROPERTY_MAX = `More than ${LANGUAGE_DEFAULT_ITEM_LENGTH} filters to show`;

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

export const TRACKING_LABEL_SET = 'set';
export const TRACKING_LABEL_CHECKBOX = 'checkbox';
