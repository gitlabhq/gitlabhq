import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/error_tracking/store/list/actions';
import * as types from '~/error_tracking/store/list/mutation_types';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import httpStatusCodes from '~/lib/utils/http_status';

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
    it('should start polling for data', (done) => {
      const payload = { errors: [{ id: 1 }, { id: 2 }] };

      mock.onGet().reply(httpStatusCodes.OK, payload);
      testAction(
        actions.startPolling,
        {},
        {},
        [
          { type: types.SET_LOADING, payload: true },
          { type: types.SET_PAGINATION, payload: payload.pagination },
          { type: types.SET_ERRORS, payload: payload.errors },
          { type: types.SET_LOADING, payload: false },
        ],
        [{ type: 'stopPolling' }],
        () => {
          done();
        },
      );
    });

    it('should show flash on API error', (done) => {
      mock.onGet().reply(httpStatusCodes.BAD_REQUEST);

      testAction(
        actions.startPolling,
        {},
        {},
        [
          { type: types.SET_LOADING, payload: true },
          { type: types.SET_LOADING, payload: false },
        ],
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
        [
          { type: types.SET_ERRORS, payload: [] },
          { type: types.SET_LOADING, payload: true },
        ],
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
          { type: types.SET_CURSOR, payload: null },
          { type: types.SET_SEARCH_QUERY, payload: query },
          { type: types.ADD_RECENT_SEARCH, payload: query },
        ],
        [{ type: 'stopPolling' }, { type: 'startPolling' }],
      );
    });
  });

  describe('filterByStatus', () => {
    it('should search errors by status', () => {
      const status = 'ignored';

      testAction(
        actions.filterByStatus,
        status,
        {},
        [{ type: types.SET_STATUS_FILTER, payload: status }],
        [{ type: 'stopPolling' }, { type: 'startPolling' }],
      );
    });
  });

  describe('sortByField', () => {
    it('should search by query', () => {
      const field = 'frequency';

      testAction(
        actions.sortByField,
        field,
        {},
        [
          { type: types.SET_CURSOR, payload: null },
          { type: types.SET_SORT_FIELD, payload: field },
        ],
        [{ type: 'stopPolling' }, { type: 'startPolling' }],
      );
    });
  });

  describe('setEndpoint', () => {
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

  describe('fetchPaginatedResults', () => {
    it('should start polling the selected page cursor', () => {
      const cursor = '1576637570000:1:1';
      testAction(
        actions.fetchPaginatedResults,
        cursor,
        {},
        [{ type: types.SET_CURSOR, payload: cursor }],
        [{ type: 'stopPolling' }, { type: 'startPolling' }],
      );
    });
  });
});
