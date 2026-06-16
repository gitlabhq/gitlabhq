import testAction from 'helpers/vuex_action_helper';

import * as Sentry from '~/sentry/sentry_browser_wrapper';
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

jest.mock('~/sentry/sentry_browser_wrapper');

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
      it('shows the fallback message when the error has no response body', async () => {
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

      it('shows the server error message when present in the response body', async () => {
        jest.spyOn(api, 'fetchSubscriptions').mockRejectedValue({
          response: { data: { message: 'Server-side error detail' } },
        });

        await testAction(
          fetchSubscriptions,
          mockUrl,
          mockedState,
          [
            { type: types.SET_SUBSCRIPTIONS_LOADING, payload: true },
            { type: types.SET_SUBSCRIPTIONS_ERROR, payload: true },
            {
              type: types.SET_ALERT,
              payload: { message: 'Server-side error detail', variant: 'danger' },
            },
            { type: types.SET_SUBSCRIPTIONS_LOADING, payload: false },
          ],
          [],
        );
      });

      it('reports the error to Sentry', async () => {
        const error = new Error('network');
        jest.spyOn(api, 'fetchSubscriptions').mockRejectedValue(error);

        await fetchSubscriptions({ commit: jest.fn() }, mockUrl);

        expect(Sentry.captureException).toHaveBeenCalledWith(error);
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
      it('rejects with the error and does not commit SET_ALERT', async () => {
        const error = {
          response: { data: { errors: 'You must be a Maintainer or Owner of the group.' } },
        };
        jest.spyOn(api, 'addJiraConnectSubscription').mockRejectedValue(error);

        await expect(
          testAction(
            addSubscription,
            { namespacePath: mockNamespace, subscriptionsPath: mockSubscriptionsPath },
            mockedState,
            [],
            [],
          ),
        ).rejects.toBe(error);
      });
    });
  });
});
