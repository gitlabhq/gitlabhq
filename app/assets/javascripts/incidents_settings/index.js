import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import SettingsTabs from './components/incidents_settings_tabs.vue';
import IncidentsSettingsService from './incidents_settings_service';

export default () => {
  const el = document.querySelector('.js-incidents-settings');

  if (!el) {
    return null;
  }

  const {
    dataset: {
      operationsSettingsEndpoint,
      templates,
      createIssue,
      issueTemplateKey,
      sendEmail,
      pagerdutyActive,
      pagerdutyWebhookUrl,
      pagerdutyResetKeyPath,
      autoCloseIncident,
      slaActive,
      slaMinutes,
      slaFeatureAvailable,
    },
  } = el;

  const service = new IncidentsSettingsService(operationsSettingsEndpoint, pagerdutyResetKeyPath);
  return new Vue({
    el,
    provide: {
      service,
      alertSettings: {
        templates: JSON.parse(templates),
        createIssue: parseBoolean(createIssue),
        issueTemplateKey,
        sendEmail: parseBoolean(sendEmail),
        autoCloseIncident: parseBoolean(autoCloseIncident),
      },
      pagerDutySettings: {
        active: parseBoolean(pagerdutyActive),
        webhookUrl: pagerdutyWebhookUrl,
      },
      serviceLevelAgreementSettings: {
        active: parseBoolean(slaActive),
        minutes: slaMinutes,
        available: parseBoolean(slaFeatureAvailable),
      },
    },
    render(createElement) {
      return createElement(SettingsTabs);
    },
  });
};
