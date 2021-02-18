import mountAlertsSettings from '~/alerts_settings';
import mountErrorTrackingForm from '~/error_tracking_settings';
import mountGrafanaIntegration from '~/grafana_integration';
import initIncidentsSettings from '~/incidents_settings';
import mountOperationSettings from '~/operation_settings';
import initSettingsPanels from '~/settings_panels';

initIncidentsSettings();
mountErrorTrackingForm();
mountOperationSettings();
mountGrafanaIntegration();
if (!IS_EE) {
  initSettingsPanels();
}
mountAlertsSettings(document.querySelector('.js-alerts-settings'));
