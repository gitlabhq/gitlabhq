import { s__ } from '~/locale';

export const i18n = {
  usageSection: s__(
    'AlertSettings|You must provide this URL and authorization key to authorize an external service to send alerts to GitLab. You can provide this URL and key to multiple services. After configuring an external service, alerts from your service will display on the GitLab %{linkStart}Alerts%{linkEnd} page.',
  ),
  setupSection: s__(
    "AlertSettings|Review your external service's documentation to learn where to provide this information to your external service, and the %{linkStart}GitLab documentation%{linkEnd} to learn more about configuring your endpoint.",
  ),
  errorMsg: s__(
    'AlertSettings|There was an error updating the the alert settings. Please refresh the page to try again.',
  ),
  errorKeyMsg: s__(
    'AlertSettings|There was an error while trying to reset the key. Please refresh the page to try again.',
  ),
  errorApiUrlMsg: s__(
    'AlertSettings|There was an error while trying to enable the alert settings. Please ensure you are using a valid URL.',
  ),
  prometheusApiPlaceholder: s__('AlertSettings|http://prometheus.example.com/'),
  restKeyInfo: s__(
    'AlertSettings|Resetting the authorization key for this project will require updating the authorization key in every alert source it is enabled in.',
  ),
  endPointActivated: s__('AlertSettings|Alerts endpoint successfully activated.'),
  prometheusInfo: s__('AlertSettings|Add URL and auth key to your Prometheus config file'),
  integrationsInfo: s__(
    'AlertSettings|Learn more about our %{linkStart}upcoming integrations%{linkEnd}',
  ),
  resetKey: s__('AlertSettings|Reset key'),
  copyToClipboard: s__('AlertSettings|Copy'),
  integrationsLabel: s__('AlertSettings|Integrations'),
  apiBaseUrlLabel: s__('AlertSettings|Prometheus API Base URL'),
  authKeyLabel: s__('AlertSettings|Authorization key'),
  urlLabel: s__('AlertSettings|Webhook URL'),
  activeLabel: s__('AlertSettings|Active'),
  apiBaseUrlHelpText: s__('  AlertSettings|URL cannot be blank and must start with http or https'),
};

export const serviceOptions = [
  { value: 'generic', text: s__('AlertSettings|Generic') },
  { value: 'prometheus', text: s__('AlertSettings|External Prometheus') },
];
