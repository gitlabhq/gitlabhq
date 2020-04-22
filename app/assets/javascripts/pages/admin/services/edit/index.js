import IntegrationSettingsForm from '~/integrations/integration_settings_form';
import initAlertsSettings from '~/alerts_service_settings';

document.addEventListener('DOMContentLoaded', () => {
  const integrationSettingsForm = new IntegrationSettingsForm('.js-integration-settings-form');
  integrationSettingsForm.init();

  initAlertsSettings(document.querySelector('.js-alerts-service-settings'));
});
