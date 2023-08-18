export default function createState({
  accessToken = null,
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

    accessToken,
  };
}
