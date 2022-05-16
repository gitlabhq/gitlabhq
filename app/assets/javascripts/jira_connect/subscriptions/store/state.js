export default function createState({ subscriptions = [], subscriptionsLoading = false } = {}) {
  return {
    alert: undefined,

    subscriptions,
    subscriptionsLoading,
    subscriptionsError: false,

    addSubscriptionLoading: false,
    addSubscriptionError: false,

    currentUser: null,
    currentUserError: null,

    accessToken: null,
  };
}
