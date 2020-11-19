const PROMETHEUS_URL = '/prometheus/alerts/notify.json';
const GENERIC_URL = '/alerts/notify.json';
const KEY = 'abcedfg123';
const INVALID_URL = 'http://invalid';
const ACTIVE = false;

export const defaultAlertSettingsConfig = {
  generic: {
    authorizationKey: KEY,
    formPath: INVALID_URL,
    url: GENERIC_URL,
    alertsSetupUrl: INVALID_URL,
    alertsUsageUrl: INVALID_URL,
    active: ACTIVE,
  },
  prometheus: {
    authorizationKey: KEY,
    prometheusFormPath: INVALID_URL,
    url: PROMETHEUS_URL,
    active: ACTIVE,
  },
  opsgenie: {
    opsgenieMvcIsAvailable: true,
    formPath: INVALID_URL,
    active: ACTIVE,
    opsgenieMvcTargetUrl: GENERIC_URL,
  },
  projectPath: '',
  multiIntegrations: true,
};
