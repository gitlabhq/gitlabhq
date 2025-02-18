import createEventHub from '~/helpers/event_hub_factory';

export const GLOBAL_ALERTS_SESSION_STORAGE_KEY = 'vueGlobalAlerts';
export const GLOBAL_ALERTS_DISMISS_EVENT = 'vueGlobalAlertsDismiss';

export const eventHub = createEventHub();

/**
 * Get global alerts from session storage
 */
export const getGlobalAlerts = () => {
  return JSON.parse(sessionStorage.getItem(GLOBAL_ALERTS_SESSION_STORAGE_KEY) || '[]');
};

/**
 * Set alerts in session storage
 * @param {{id: String, title?: String, message: String, variant: String, dismissible?: Boolean, persistOnPages?: String[]}[]} alerts
 */
export const setGlobalAlerts = (alerts) => {
  sessionStorage.setItem(
    GLOBAL_ALERTS_SESSION_STORAGE_KEY,
    JSON.stringify([
      ...alerts.map(({ dismissible = true, persistOnPages = [], ...alert }) => ({
        dismissible,
        persistOnPages,
        ...alert,
      })),
    ]),
  );
};

/**
 * Remove global alert by id
 * @param {String} id
 */
export const removeGlobalAlertById = (id) => {
  const existingAlerts = getGlobalAlerts();
  sessionStorage.setItem(
    GLOBAL_ALERTS_SESSION_STORAGE_KEY,
    JSON.stringify(existingAlerts.filter((alert) => alert.id !== id)),
  );
};

/**
 * Programmatically dismiss global alert by id
 * @param {String} id
 */
export const dismissGlobalAlertById = (id) => {
  eventHub.$emit(GLOBAL_ALERTS_DISMISS_EVENT, id);
};
