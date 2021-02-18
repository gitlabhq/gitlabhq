import { s__, __ } from '~/locale';

export const INTEGRATION_VIEW_CONFIGS = {
  sourcegraph: {
    title: s__('Preferences|Sourcegraph'),
    label: s__('Preferences|Enable integrated code intelligence on code views'),
    formName: 'sourcegraph_enabled',
  },
  gitpod: {
    title: s__('Preferences|Gitpod'),
    label: s__('Preferences|Enable Gitpod integration'),
    formName: 'gitpod_enabled',
  },
};

export const i18n = {
  saveChanges: __('Save changes'),
  defaultSuccess: __('Preferences saved.'),
  defaultError: s__('Preferences|Failed to save preferences.'),
  integrations: s__('Preferences|Integrations'),
  integrationsDescription: s__('Preferences|Customize integrations with third party services.'),
};
