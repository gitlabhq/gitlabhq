import mountErrorTrackingForm from '~/error_tracking_settings';
import initAlertsSettings from '~/alerts_service_settings';
import mountOperationSettings from '~/operation_settings';
import mountGrafanaIntegration from '~/grafana_integration';
import initSettingsPanels from '~/settings_panels';

document.addEventListener('DOMContentLoaded', () => {
  mountErrorTrackingForm();
  mountOperationSettings();
  mountGrafanaIntegration();
  if (!IS_EE) {
    initSettingsPanels();
  }
  initAlertsSettings(document.querySelector('.js-alerts-service-settings'));
});
