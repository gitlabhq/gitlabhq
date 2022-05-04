import {
  SET_ALERT,
  SET_SUBSCRIPTIONS,
  SET_SUBSCRIPTIONS_LOADING,
  SET_SUBSCRIPTIONS_ERROR,
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
};
