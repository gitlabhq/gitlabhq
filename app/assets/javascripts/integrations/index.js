/* eslint-disable no-new */
import IntegrationSettingsForm from './integration_settings_form';

$(() => {
  const integrationSettingsForm = new IntegrationSettingsForm('.js-integration-settings-form');
  integrationSettingsForm.init();
});
