import {
  DISMISSED_CREATION_ALERTS_LIMIT,
  DISMISSED_CREATION_ALERTS_STORAGE_KEY_BASE,
} from './constants';

// Failed requests worth alerting on: automatic (background) creation attempts
// and already-dismissed requests are excluded.
export const alertableFailedRequests = (requests = [], dismissedIds = []) =>
  requests.filter(
    (request) =>
      request.status === 'FAILED' &&
      request.userInitiated !== false &&
      !dismissedIds.includes(request.id),
  );

export const dismissedCreationAlertsStorageKey = (targetProjectFullPath, mergeRequestId) =>
  `${DISMISSED_CREATION_ALERTS_STORAGE_KEY_BASE}_${targetProjectFullPath}_${mergeRequestId}`;

export const hasAlertableFailureCountIncreased = (
  previousRequests = [],
  currentRequests = [],
  dismissedIds = [],
) =>
  alertableFailedRequests(currentRequests, dismissedIds).length >
  alertableFailedRequests(previousRequests, dismissedIds).length;

// Returns the dismissed-id list after dismissing the currently alertable failures.
// null ids (requests written before the id field existed) can't persist a dismissal,
// and the list is capped at the most recent DISMISSED_CREATION_ALERTS_LIMIT entries.
export const nextDismissedCreationRequestIds = (requests = [], dismissedIds = []) => {
  const alertedIds = alertableFailedRequests(requests, dismissedIds)
    .map((request) => request.id)
    .filter(Boolean);

  if (!alertedIds.length) return dismissedIds;

  return [...dismissedIds, ...alertedIds].slice(-DISMISSED_CREATION_ALERTS_LIMIT);
};

export const createSubscriptionsCollection = () => {
  const subscriptions = new Map();

  return {
    syncSubscriptions(ids, factory) {
      const desiredSet = new Set(ids);
      for (const [id, unsubscribe] of subscriptions) {
        if (!desiredSet.has(id)) {
          unsubscribe();
          subscriptions.delete(id);
        }
      }
      for (const id of ids) {
        if (!subscriptions.has(id)) {
          const unsubscribe = factory(id);
          subscriptions.set(id, unsubscribe);
        }
      }
    },
    unsubscribeAll() {
      for (const unsubscribe of subscriptions.values()) {
        unsubscribe();
      }
      subscriptions.clear();
    },
  };
};
