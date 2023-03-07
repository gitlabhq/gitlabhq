import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/error_tracking/store/actions';
import * as types from '~/error_tracking/store/mutation_types';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility');

let mock;
const commit = jest.fn();
const dispatch = jest.fn().mockResolvedValue();

describe('Sentry common store actions', () => {
  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    createAlert.mockClear();
  });
  const endpoint = '123/stacktrace';
  const redirectUrl = '/list';
  const status = 'resolved';
  const params = { endpoint, redirectUrl, status };

  describe('updateStatus', () => {
    it('should handle successful status update', async () => {
      mock.onPut().reply(HTTP_STATUS_OK, {});
      await testAction(
        actions.updateStatus,
        params,
        {},
        [
          {
            payload: 'resolved',
            type: types.SET_ERROR_STATUS,
          },
        ],
        [],
      );
      expect(visitUrl).toHaveBeenCalledWith(redirectUrl);
    });

    it('should handle unsuccessful status update', async () => {
      mock.onPut().reply(HTTP_STATUS_BAD_REQUEST, {});
      await testAction(actions.updateStatus, params, {}, [], []);
      expect(visitUrl).not.toHaveBeenCalled();
      expect(createAlert).toHaveBeenCalledTimes(1);
    });
  });

  describe('updateResolveStatus', () => {
    it('handles status update', () =>
      actions.updateResolveStatus({ commit, dispatch }, params).then(() => {
        expect(commit).toHaveBeenCalledWith(types.SET_UPDATING_RESOLVE_STATUS, true);
        expect(commit).toHaveBeenCalledWith(types.SET_UPDATING_RESOLVE_STATUS, false);
        expect(dispatch).toHaveBeenCalledWith('updateStatus', params);
      }));
  });

  describe('updateIgnoreStatus', () => {
    it('handles status update', () =>
      actions.updateIgnoreStatus({ commit, dispatch }, params).then(() => {
        expect(commit).toHaveBeenCalledWith(types.SET_UPDATING_IGNORE_STATUS, true);
        expect(commit).toHaveBeenCalledWith(types.SET_UPDATING_IGNORE_STATUS, false);
        expect(dispatch).toHaveBeenCalledWith('updateStatus', params);
      }));
  });
});
