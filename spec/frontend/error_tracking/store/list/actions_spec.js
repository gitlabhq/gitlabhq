import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';
import * as actions from '~/error_tracking/store/list/actions';
import * as types from '~/error_tracking/store/list/mutation_types';

describe('error tracking actions', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('startPolling', () => {
    it('commits SET_LOADING', () => {
      mock.onGet().reply(200);
      const endpoint = '/errors';
      const commit = jest.fn();
      const state = {};

      actions.startPolling({ commit, state }, endpoint);

      expect(commit).toHaveBeenCalledWith(types.SET_LOADING, true);
    });
  });
});
