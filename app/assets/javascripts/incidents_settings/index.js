import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
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
      pagerdutyActive,
      pagerdutyWebhookUrl,
      pagerdutyResetKeyPath,
      slaActive,
      slaMinutes,
      slaFeatureAvailable,
    },
  } = el;

  const service = new IncidentsSettingsService(operationsSettingsEndpoint, pagerdutyResetKeyPath);
  return initVueApp({
    el,
    name: 'IncidentsSettingsTabsRoot',
    provide: {
      service,
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
    component: SettingsTabs,
  });
};
