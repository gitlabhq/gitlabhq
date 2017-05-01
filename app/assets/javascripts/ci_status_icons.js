import CANCELED_SVG from 'icons/_icon_status_canceled_borderless.svg';
import CREATED_SVG from 'icons/_icon_status_created_borderless.svg';
import FAILED_SVG from 'icons/_icon_status_failed_borderless.svg';
import MANUAL_SVG from 'icons/_icon_status_manual_borderless.svg';
import PENDING_SVG from 'icons/_icon_status_pending_borderless.svg';
import RUNNING_SVG from 'icons/_icon_status_running_borderless.svg';
import SKIPPED_SVG from 'icons/_icon_status_skipped_borderless.svg';
import SUCCESS_SVG from 'icons/_icon_status_success_borderless.svg';
import WARNING_SVG from 'icons/_icon_status_warning_borderless.svg';
import NOT_FOUND_SVG from 'icons/_icon_status_not_found_borderless.svg';

const StatusIconEntityMap = {
  icon_status_canceled: CANCELED_SVG,
  icon_status_created: CREATED_SVG,
  icon_status_failed: FAILED_SVG,
  icon_status_manual: MANUAL_SVG,
  icon_status_pending: PENDING_SVG,
  icon_status_running: RUNNING_SVG,
  icon_status_skipped: SKIPPED_SVG,
  icon_status_success: SUCCESS_SVG,
  icon_status_warning: WARNING_SVG,
  icon_status_not_found: NOT_FOUND_SVG,
};

export {
  CANCELED_SVG,
  CREATED_SVG,
  FAILED_SVG,
  MANUAL_SVG,
  PENDING_SVG,
  RUNNING_SVG,
  SKIPPED_SVG,
  SUCCESS_SVG,
  WARNING_SVG,
  NOT_FOUND_SVG,
  StatusIconEntityMap as default,
};
