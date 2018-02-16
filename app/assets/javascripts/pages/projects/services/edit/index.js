import IntegrationSettingsForm from '~/integrations/integration_settings_form';

export default () => {
  const integrationSettingsForm = new IntegrationSettingsForm('.js-integration-settings-form');
  integrationSettingsForm.init();
};
