import Tracking from '~/tracking';

export const TRACKING_CATEGORY = 'Language filters';
export const TRACKING_LABEL_FILTER = 'Label Key';

export const TRACKING_LABEL_DROPDOWN = 'Dropdown';
export const TRACKING_LABEL_CHECKBOX = 'Label Checkbox';

export const TRACKING_ACTION_SELECT = 'search:agreggations:label:select';
export const TRACKING_ACTION_SHOW = 'search:agreggations:label:show';

export const trackSelectCheckbox = (value) =>
  Tracking.event(TRACKING_ACTION_SELECT, TRACKING_LABEL_CHECKBOX, {
    label: TRACKING_LABEL_FILTER,
    property: value,
  });

export const trackOpenDropdown = () =>
  Tracking.event(TRACKING_ACTION_SHOW, TRACKING_LABEL_DROPDOWN, {
    label: TRACKING_LABEL_DROPDOWN,
  });
