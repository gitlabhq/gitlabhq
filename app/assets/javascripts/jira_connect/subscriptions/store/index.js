import { defineStore } from 'pinia';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import {
  addJiraConnectSubscription,
  fetchSubscriptions as fetchSubscriptionsREST,
  getCurrentUser,
} from '~/jira_connect/subscriptions/api';
import {
  I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_MESSAGE,
  I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_TITLE,
  I18N_DEFAULT_SUBSCRIPTIONS_ERROR_MESSAGE,
  INTEGRATIONS_DOC_LINK,
} from '../constants';
import { getJwt } from '../utils';

export const useJiraConnectSubscriptions = defineStore('jiraConnectSubscriptions', {
  state: () => ({
    alert: undefined,
    subscriptions: [],
    subscriptionsLoading: false,
    subscriptionsError: false,
    currentUser: null,
    currentUserError: null,
    accessToken: null,
  }),
  actions: {
    setAlert({ title, message, variant, linkUrl } = {}) {
      this.alert = { title, message, variant, linkUrl };
    },
    setAccessToken(accessToken) {
      this.accessToken = accessToken;
    },
    async fetchSubscriptions(subscriptionsPath) {
      this.subscriptionsLoading = true;
      try {
        const data = await fetchSubscriptionsREST(subscriptionsPath);
        this.subscriptions = data.data.subscriptions;
      } catch (error) {
        this.subscriptionsError = true;
        const message =
          error?.response?.data?.errors ||
          error?.response?.data?.message ||
          I18N_DEFAULT_SUBSCRIPTIONS_ERROR_MESSAGE;
        this.setAlert({ message, variant: 'danger' });
        Sentry.captureException(error);
      } finally {
        this.subscriptionsLoading = false;
      }
    },
    async loadCurrentUser(accessToken) {
      try {
        const { data: user } = await getCurrentUser({
          // eslint-disable-next-line @gitlab/require-i18n-strings -- False positive
          headers: { Authorization: `Bearer ${accessToken}` },
        });
        this.currentUser = user;
      } catch (e) {
        this.currentUserError = e;
      }
    },
    async addSubscription({ namespacePath, subscriptionsPath }) {
      await addJiraConnectSubscription(namespacePath, {
        jwt: await getJwt(),
        accessToken: this.accessToken,
      });

      this.setAlert({
        title: I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_TITLE,
        message: I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_MESSAGE,
        linkUrl: INTEGRATIONS_DOC_LINK,
        variant: 'success',
      });

      this.fetchSubscriptions(subscriptionsPath);
    },
  },
});
