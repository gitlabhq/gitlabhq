import mountErrorTrackingForm from '~/error_tracking_settings';
import mountOperationSettings from '~/operation_settings';
import initSettingsPanels from '~/settings_panels';

document.addEventListener('DOMContentLoaded', () => {
  mountErrorTrackingForm();
  mountOperationSettings();
  initSettingsPanels();
});
