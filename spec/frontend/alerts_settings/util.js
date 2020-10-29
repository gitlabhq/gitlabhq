const PROMETHEUS_URL = '/prometheus/alerts/notify.json';
const GENERIC_URL = '/alerts/notify.json';
const KEY = 'abcedfg123';
const INVALID_URL = 'http://invalid';
const ACTIVATED = false;

export const defaultAlertSettingsConfig = {
  generic: {
    authorizationKey: KEY,
    formPath: INVALID_URL,
    url: GENERIC_URL,
    alertsSetupUrl: INVALID_URL,
    alertsUsageUrl: INVALID_URL,
    activated: ACTIVATED,
  },
  prometheus: {
    authorizationKey: KEY,
    prometheusFormPath: INVALID_URL,
    prometheusUrl: PROMETHEUS_URL,
    activated: ACTIVATED,
  },
  opsgenie: {
    opsgenieMvcIsAvailable: true,
    formPath: INVALID_URL,
    activated: ACTIVATED,
    opsgenieMvcTargetUrl: GENERIC_URL,
  },
};
