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

    currentUser,
    currentUserError: null,

    accessToken: null,
  };
}
