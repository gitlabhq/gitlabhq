import {
  SET_ALERT,
  SET_SUBSCRIPTIONS,
  SET_SUBSCRIPTIONS_LOADING,
  SET_SUBSCRIPTIONS_ERROR,
  SET_CURRENT_USER,
  SET_CURRENT_USER_ERROR,
  SET_ACCESS_TOKEN,
} from './mutation_types';

export default {
  [SET_ALERT](state, { title, message, variant, linkUrl } = {}) {
    state.alert = { title, message, variant, linkUrl };
  },

  [SET_SUBSCRIPTIONS](state, subscriptions = []) {
    state.subscriptions = subscriptions;
  },
  [SET_SUBSCRIPTIONS_LOADING](state, subscriptionsLoading) {
    state.subscriptionsLoading = subscriptionsLoading;
  },
  [SET_SUBSCRIPTIONS_ERROR](state, subscriptionsError) {
    state.subscriptionsError = subscriptionsError;
  },

  [SET_CURRENT_USER](state, currentUser) {
    state.currentUser = currentUser;
  },
  [SET_CURRENT_USER_ERROR](state, currentUserError) {
    state.currentUserError = currentUserError;
  },

  [SET_ACCESS_TOKEN](state, accessToken) {
    state.accessToken = accessToken;
  },
};
