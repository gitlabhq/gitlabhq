import mountAlertsSettings from '~/alerts_settings';
import mountErrorTrackingForm from '~/error_tracking_settings';
import initIncidentsSettings from '~/incidents_settings';
import initSettingsPanels from '~/settings_panels';

initIncidentsSettings();
mountErrorTrackingForm();
if (!IS_EE) {
  initSettingsPanels();
}
mountAlertsSettings(document.querySelector('.js-alerts-settings'));
