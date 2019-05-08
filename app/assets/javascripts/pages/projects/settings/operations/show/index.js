import mountErrorTrackingForm from '~/error_tracking_settings';
import mountOperationSettings from '~/operation_settings';

document.addEventListener('DOMContentLoaded', () => {
  mountErrorTrackingForm();
  mountOperationSettings();
});
