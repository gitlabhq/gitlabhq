import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import httpStatusCodes from '~/lib/utils/http_status';
import createFlash from '~/flash';
import * as actions from '~/error_tracking/store/list/actions';
import * as types from '~/error_tracking/store/list/mutation_types';

jest.mock('~/flash.js');

describe('error tracking actions', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('startPolling', () => {
    it('should start polling for data', done => {
      const payload = { errors: [{ id: 1 }, { id: 2 }] };

      mock.onGet().reply(httpStatusCodes.OK, payload);
      testAction(
        actions.startPolling,
        {},
        {},
        [
          { type: types.SET_LOADING, payload: true },
          { type: types.SET_ERRORS, payload: payload.errors },
          { type: types.SET_LOADING, payload: false },
        ],
        [{ type: 'stopPolling' }],
        () => {
          done();
        },
      );
    });

    it('should show flash on API error', done => {
      mock.onGet().reply(httpStatusCodes.BAD_REQUEST);

      testAction(
        actions.startPolling,
        {},
        {},
        [{ type: types.SET_LOADING, payload: true }, { type: types.SET_LOADING, payload: false }],
        [],
        () => {
          expect(createFlash).toHaveBeenCalledTimes(1);
          done();
        },
      );
    });
  });

  describe('restartPolling', () => {
    it('should restart polling', () => {
      testAction(
        actions.restartPolling,
        {},
        {},
        [{ type: types.SET_ERRORS, payload: [] }, { type: types.SET_LOADING, payload: true }],
        [],
      );
    });
  });

  describe('searchByQuery', () => {
    it('should search by query', () => {
      const query = 'search';

      testAction(
        actions.searchByQuery,
        query,
        {},
        [
          { type: types.SET_SEARCH_QUERY, payload: query },
          { type: types.ADD_RECENT_SEARCH, payload: query },
        ],
        [{ type: 'stopPolling' }, { type: 'startPolling' }],
      );
    });
  });

  describe('sortByField', () => {
    it('should search by query', () => {
      const field = 'frequency';

      testAction(
        actions.sortByField,
        { field },
        {},
        [{ type: types.SET_SORT_FIELD, payload: { field } }],
        [{ type: 'stopPolling' }, { type: 'startPolling' }],
      );
    });
  });

  describe('setEnpoint', () => {
    it('should set search endpoint', () => {
      const endpoint = 'https://sentry.io';

      testAction(
        actions.setEndpoint,
        { endpoint },
        {},
        [{ type: types.SET_ENDPOINT, payload: { endpoint } }],
        [],
      );
    });
  });
});
