import IncidentsSettingsService from '~/incidents_settings/incidents_settings_service';
import { parseBoolean } from '~/lib/utils/common_utils';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import AlertSettingsWrapper from './components/alerts_settings_wrapper.vue';
import apolloProvider from './graphql';
import getCurrentIntegrationQuery from './graphql/queries/get_current_integration.query.graphql';

apolloProvider.clients.defaultClient.cache.writeQuery({
  query: getCurrentIntegrationQuery,
  data: {
    currentIntegration: null,
  },
});

export default (el) => {
  if (!el) {
    return null;
  }

  const {
    alertsUsageUrl,
    projectPath,
    multiIntegrations,
    alertFields,
    templates,
    createIssue,
    issueTemplateKey,
    sendEmail,
    autoCloseIncident,
    pagerdutyResetKeyPath,
    operationsSettingsEndpoint,
  } = el.dataset;

  const service = new IncidentsSettingsService(operationsSettingsEndpoint, pagerdutyResetKeyPath);
  return initVueApp({
    el,
    name: 'AlertSettingsWrapperRoot',
    component: AlertSettingsWrapper,
    props: {
      alertFields: parseBoolean(multiIntegrations) ? JSON.parse(alertFields) : null,
    },
    provide: {
      service,
      alertSettings: {
        templates: JSON.parse(templates),
        createIssue: parseBoolean(createIssue),
        issueTemplateKey,
        sendEmail: parseBoolean(sendEmail),
        autoCloseIncident: parseBoolean(autoCloseIncident),
        pagerdutyResetKeyPath,
        operationsSettingsEndpoint,
      },
      alertsUsageUrl,
      projectPath,
      multiIntegrations: parseBoolean(multiIntegrations),
    },
    apolloProvider,
  });
};
