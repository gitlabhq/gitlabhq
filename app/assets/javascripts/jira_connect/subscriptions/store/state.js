export default function createState({
  subscriptions = [],
  subscriptionsLoading = false,
  currentUser = null,
} = {}) {
  return {
    alert: undefined,

    subscriptions,
    subscriptionsLoading,
    subscriptionsError: false,

    addSubscriptionLoading: false,
    addSubscriptionError: false,

    currentUser,
    currentUserError: null,

    accessToken: null,
  };
}
