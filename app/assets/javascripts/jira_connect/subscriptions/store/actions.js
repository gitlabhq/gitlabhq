import { fetchSubscriptions as fetchSubscriptionsREST } from '~/jira_connect/subscriptions/api';
import { I18N_DEFAULT_SUBSCRIPTIONS_ERROR_MESSAGE } from '../constants';
import {
  SET_SUBSCRIPTIONS,
  SET_SUBSCRIPTIONS_LOADING,
  SET_SUBSCRIPTIONS_ERROR,
  SET_ALERT,
} from './mutation_types';

export const fetchSubscriptions = async ({ commit }, subscriptionsPath) => {
  commit(SET_SUBSCRIPTIONS_LOADING, true);

  try {
    const data = await fetchSubscriptionsREST(subscriptionsPath);
    commit(SET_SUBSCRIPTIONS, data.data.subscriptions);
  } catch {
    commit(SET_SUBSCRIPTIONS_ERROR, true);
    commit(SET_ALERT, { message: I18N_DEFAULT_SUBSCRIPTIONS_ERROR_MESSAGE, variant: 'danger' });
  } finally {
    commit(SET_SUBSCRIPTIONS_LOADING, false);
  }
};
