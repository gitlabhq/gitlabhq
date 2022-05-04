export default function createState({ subscriptions = [], subscriptionsLoading = false } = {}) {
  return {
    alert: undefined,
    subscriptions,
    subscriptionsLoading,
    subscriptionsError: false,
  };
}
