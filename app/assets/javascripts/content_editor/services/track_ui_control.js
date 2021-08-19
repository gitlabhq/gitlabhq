import Tracking from '~/tracking';
import { CONTENT_EDITOR_TRACKING_LABEL, TOOLBAR_CONTROL_TRACKING_ACTION } from '../constants';

export default ({ action = TOOLBAR_CONTROL_TRACKING_ACTION, property, value } = {}) =>
  Tracking.event(undefined, action, {
    label: CONTENT_EDITOR_TRACKING_LABEL,
    property,
    value,
  });
