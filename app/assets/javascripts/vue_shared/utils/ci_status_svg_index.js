import canceledBase from 'icons/_icon_status_canceled.svg';
import createdBase from 'icons/_icon_status_created.svg';
import failedBase from 'icons/_icon_status_failed.svg';
import manualBase from 'icons/_icon_status_manual.svg';
import pendingBase from 'icons/_icon_status_pending.svg';
import runningBase from 'icons/_icon_status_running.svg';
import skippedBase from 'icons/_icon_status_skipped.svg';
import successBase from 'icons/_icon_status_success.svg';
import warningBase from 'icons/_icon_status_warning.svg';

import canceledBorderless from 'icons/_icon_status_canceled_borderless.svg';
import createdBorderless from 'icons/_icon_status_created_borderless.svg';
import failedBorderless from 'icons/_icon_status_failed_borderless.svg';
import manualBorderless from 'icons/_icon_status_manual_borderless.svg';
import pendingBorderless from 'icons/_icon_status_pending_borderless.svg';
import runningBorderless from 'icons/_icon_status_running_borderless.svg';
import skippedBorderless from 'icons/_icon_status_skipped_borderless.svg';
import successBorderless from 'icons/_icon_status_success_borderless.svg';
import warningBorderless from 'icons/_icon_status_warning_borderless.svg';

// note that some svgs are reused for more than one state (e.g. successBase)

export const baseIcons = {
  canceled: canceledBase,
  created: createdBase,
  failed: failedBase,
  manual: manualBase,
  pending: pendingBase,
  running: runningBase,
  skipped: skippedBase,
  success: successBase,
  warning: warningBase,
};

export const borderlessIcons = {
  canceled: canceledBorderless,
  created: createdBorderless,
  failed: failedBorderless,
  manual: manualBorderless,
  pending: pendingBorderless,
  running: runningBorderless,
  skipped: skippedBorderless,
  success: successBorderless,
  warning: warningBorderless,
};
