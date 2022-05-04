import testAction from 'helpers/vuex_action_helper';

import * as types from '~/jira_connect/subscriptions/store/mutation_types';
import { fetchSubscriptions } from '~/jira_connect/subscriptions/store/actions';
import state from '~/jira_connect/subscriptions/store/state';
import * as api from '~/jira_connect/subscriptions/api';
import { I18N_DEFAULT_SUBSCRIPTIONS_ERROR_MESSAGE } from '~/jira_connect/subscriptions/constants';

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
});
