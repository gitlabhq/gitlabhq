import {
  fetchSubscriptions as fetchSubscriptionsREST,
  getCurrentUser,
  addJiraConnectSubscription,
} from '~/jira_connect/subscriptions/api';
import {
  I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_TITLE,
  I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_MESSAGE,
  INTEGRATIONS_DOC_LINK,
  I18N_DEFAULT_SUBSCRIPTIONS_ERROR_MESSAGE,
} from '../constants';
import { getJwt } from '../utils';
import {
  SET_SUBSCRIPTIONS,
  SET_SUBSCRIPTIONS_LOADING,
  SET_SUBSCRIPTIONS_ERROR,
  SET_ALERT,
  SET_CURRENT_USER,
  SET_CURRENT_USER_ERROR,
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

export const loadCurrentUser = async ({ commit }, accessToken) => {
  try {
    const { data: user } = await getCurrentUser({
      headers: { Authorization: `Bearer ${accessToken}` },
    });

    commit(SET_CURRENT_USER, user);
  } catch (e) {
    commit(SET_CURRENT_USER_ERROR, e);
  }
};

export const addSubscription = async (
  { commit, state, dispatch },
  { namespacePath, subscriptionsPath },
) => {
  await addJiraConnectSubscription(namespacePath, {
    jwt: await getJwt(),
    accessToken: state.accessToken,
  });

  commit(SET_ALERT, {
    title: I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_TITLE,
    message: I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_MESSAGE,
    linkUrl: INTEGRATIONS_DOC_LINK,
    variant: 'success',
  });

  dispatch('fetchSubscriptions', subscriptionsPath);
};
