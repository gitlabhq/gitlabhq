import testAction from 'helpers/vuex_action_helper';

import * as types from '~/jira_connect/subscriptions/store/mutation_types';
import {
  fetchSubscriptions,
  loadCurrentUser,
  addSubscription,
} from '~/jira_connect/subscriptions/store/actions';
import state from '~/jira_connect/subscriptions/store/state';
import * as api from '~/jira_connect/subscriptions/api';
import {
  I18N_DEFAULT_SUBSCRIPTIONS_ERROR_MESSAGE,
  I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_TITLE,
  I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_MESSAGE,
  INTEGRATIONS_DOC_LINK,
} from '~/jira_connect/subscriptions/constants';
import * as utils from '~/jira_connect/subscriptions/utils';

describe('JiraConnect actions', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state();
  });

  describe('fetchSubscriptions', () => {
    const mockUrl = '/mock-url';

    describe('when API request is successful', () => {
      it('should commit SET_SUBSCRIPTIONS_LOADING and SET_SUBSCRIPTIONS mutations', async () => {
        jest.spyOn(api, 'fetchSubscriptions').mockResolvedValue({ data: { subscriptions: [] } });

        await testAction(
          fetchSubscriptions,
          mockUrl,
          mockedState,
          [
            { type: types.SET_SUBSCRIPTIONS_LOADING, payload: true },
            { type: types.SET_SUBSCRIPTIONS, payload: [] },
            { type: types.SET_SUBSCRIPTIONS_LOADING, payload: false },
          ],
          [],
        );

        expect(api.fetchSubscriptions).toHaveBeenCalledWith(mockUrl);
      });
    });

    describe('when API request fails', () => {
      it('should commit SET_SUBSCRIPTIONS_LOADING, SET_SUBSCRIPTIONS_ERROR and SET_ALERT mutations', async () => {
        jest.spyOn(api, 'fetchSubscriptions').mockRejectedValue();

        await testAction(
          fetchSubscriptions,
          mockUrl,
          mockedState,
          [
            { type: types.SET_SUBSCRIPTIONS_LOADING, payload: true },
            { type: types.SET_SUBSCRIPTIONS_ERROR, payload: true },
            {
              type: types.SET_ALERT,
              payload: { message: I18N_DEFAULT_SUBSCRIPTIONS_ERROR_MESSAGE, variant: 'danger' },
            },
            { type: types.SET_SUBSCRIPTIONS_LOADING, payload: false },
          ],
          [],
        );

        expect(api.fetchSubscriptions).toHaveBeenCalledWith(mockUrl);
      });
    });
  });

  describe('loadCurrentUser', () => {
    const mockAccessToken = 'abcd1234';

    describe('when API request succeeds', () => {
      it('commits the SET_ACCESS_TOKEN and SET_CURRENT_USER mutations', async () => {
        const mockUser = { name: 'root' };
        jest.spyOn(api, 'getCurrentUser').mockResolvedValue({ data: mockUser });

        await testAction(
          loadCurrentUser,
          mockAccessToken,
          mockedState,
          [{ type: types.SET_CURRENT_USER, payload: mockUser }],
          [],
        );

        expect(api.getCurrentUser).toHaveBeenCalledWith({
          headers: { Authorization: `Bearer ${mockAccessToken}` },
        });
      });
    });

    describe('when API request fails', () => {
      it('commits the SET_CURRENT_USER_ERROR mutation', async () => {
        jest.spyOn(api, 'getCurrentUser').mockRejectedValue();

        await testAction(
          loadCurrentUser,
          mockAccessToken,
          mockedState,
          [{ type: types.SET_CURRENT_USER_ERROR }],
          [],
        );
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
      it('commits the SET_ALERT mutation', async () => {
        jest.spyOn(api, 'addJiraConnectSubscription').mockResolvedValue({ success: true });

        await testAction(
          addSubscription,
          { namespacePath: mockNamespace, subscriptionsPath: mockSubscriptionsPath },
          mockedState,
          [
            {
              type: types.SET_ALERT,
              payload: {
                title: I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_TITLE,
                message: I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_MESSAGE,
                linkUrl: INTEGRATIONS_DOC_LINK,
                variant: 'success',
              },
            },
          ],
          [{ type: 'fetchSubscriptions', payload: mockSubscriptionsPath }],
        );

        expect(api.addJiraConnectSubscription).toHaveBeenCalledWith(mockNamespace, {
          accessToken: null,
          jwt: '1234',
        });
      });
    });

    describe('when API request fails', () => {
      it('does not commit the SET_ALERT mutation', () => {
        jest.spyOn(api, 'addJiraConnectSubscription').mockRejectedValue();

        // We need the empty catch(), since we are testing rejecting the promise,
        // which would otherwise cause the test to fail.
        testAction(
          addSubscription,
          { namespacePath: mockNamespace, subscriptionsPath: mockSubscriptionsPath },
          mockedState,
          [],
          [],
        ).catch(() => {});
      });
    });
  });
});
