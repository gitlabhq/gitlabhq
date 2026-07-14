import { createTestingPinia } from '@pinia/testing';
import * as api from '~/jira_connect/subscriptions/api';
import {
  I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_MESSAGE,
  I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_TITLE,
  I18N_DEFAULT_SUBSCRIPTIONS_ERROR_MESSAGE,
  INTEGRATIONS_DOC_LINK,
} from '~/jira_connect/subscriptions/constants';
import { useJiraConnectSubscriptions } from '~/jira_connect/subscriptions/store';
import * as utils from '~/jira_connect/subscriptions/utils';

describe('~/jira_connect/subscriptions/store', () => {
  let store;

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    store = useJiraConnectSubscriptions();
  });

  describe('setAlert', () => {
    it('sets alert state', () => {
      store.setAlert({
        message: 'test error',
        variant: 'danger',
        title: 'test title',
        linkUrl: 'linkUrl',
      });

      expect(store.alert).toMatchObject({
        message: 'test error',
        variant: 'danger',
        title: 'test title',
        linkUrl: 'linkUrl',
      });
    });
  });

  describe('setAccessToken', () => {
    it('sets accessToken', () => {
      store.setAccessToken('asdf1234');

      expect(store.accessToken).toBe('asdf1234');
    });
  });

  describe('fetchSubscriptions', () => {
    const mockUrl = '/mock-url';

    it('sets subscriptionsLoading=true while the request is in flight', () => {
      jest.spyOn(api, 'fetchSubscriptions').mockReturnValueOnce(new Promise(() => {}));

      store.fetchSubscriptions(mockUrl);

      expect(store.subscriptionsLoading).toBe(true);
    });

    describe('when API request is successful', () => {
      it('stores subscriptions and resets subscriptionsLoading', async () => {
        const mockSubscriptions = [{ name: 'test' }];
        jest
          .spyOn(api, 'fetchSubscriptions')
          .mockResolvedValue({ data: { subscriptions: mockSubscriptions } });

        await store.fetchSubscriptions(mockUrl);

        expect(api.fetchSubscriptions).toHaveBeenCalledWith(mockUrl);
        expect(store.subscriptions).toEqual(mockSubscriptions);
        expect(store.subscriptionsLoading).toBe(false);
      });
    });

    describe('when API request fails', () => {
      it('sets subscriptionsError, alert, and resets subscriptionsLoading', async () => {
        jest.spyOn(api, 'fetchSubscriptions').mockRejectedValue();

        await store.fetchSubscriptions(mockUrl);

        expect(api.fetchSubscriptions).toHaveBeenCalledWith(mockUrl);
        expect(store.subscriptionsError).toBe(true);
        expect(store.alert).toMatchObject({
          message: I18N_DEFAULT_SUBSCRIPTIONS_ERROR_MESSAGE,
          variant: 'danger',
        });
        expect(store.subscriptionsLoading).toBe(false);
      });
    });
  });

  describe('loadCurrentUser', () => {
    const mockAccessToken = 'abcd1234';

    describe('when API request succeeds', () => {
      it('sets currentUser', async () => {
        const mockUser = { name: 'root' };
        jest.spyOn(api, 'getCurrentUser').mockResolvedValue({ data: mockUser });

        await store.loadCurrentUser(mockAccessToken);

        expect(api.getCurrentUser).toHaveBeenCalledWith({
          headers: { Authorization: `Bearer ${mockAccessToken}` },
        });
        expect(store.currentUser).toEqual(mockUser);
      });
    });

    describe('when API request fails', () => {
      it('sets currentUserError', async () => {
        const error = new Error('fail');
        jest.spyOn(api, 'getCurrentUser').mockRejectedValue(error);

        await store.loadCurrentUser(mockAccessToken);

        expect(store.currentUserError).toBe(error);
      });
    });
  });

  describe('addSubscription', () => {
    const mockNamespace = 'gitlab-org/gitlab';
    const mockSubscriptionsPath = '/subscriptions';

    beforeEach(() => {
      jest.spyOn(utils, 'getJwt').mockReturnValue('1234');
    });

    describe('when API request succeeds', () => {
      it('sets the success alert and triggers fetchSubscriptions', async () => {
        jest.spyOn(api, 'addJiraConnectSubscription').mockResolvedValue({ success: true });
        const fetchSubscriptionsSpy = jest.spyOn(store, 'fetchSubscriptions').mockImplementation();

        await store.addSubscription({
          namespacePath: mockNamespace,
          subscriptionsPath: mockSubscriptionsPath,
        });

        expect(api.addJiraConnectSubscription).toHaveBeenCalledWith(mockNamespace, {
          accessToken: null,
          jwt: '1234',
        });
        expect(store.alert).toMatchObject({
          title: I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_TITLE,
          message: I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_MESSAGE,
          linkUrl: INTEGRATIONS_DOC_LINK,
          variant: 'success',
        });
        expect(fetchSubscriptionsSpy).toHaveBeenCalledWith(mockSubscriptionsPath);
      });
    });

    describe('when API request fails', () => {
      it('does not set the alert', async () => {
        jest.spyOn(api, 'addJiraConnectSubscription').mockRejectedValue(new Error('API Error'));

        await expect(
          store.addSubscription({
            namespacePath: mockNamespace,
            subscriptionsPath: mockSubscriptionsPath,
          }),
        ).rejects.toThrow('API Error');

        expect(store.alert).toBeUndefined();
      });
    });
  });
});
