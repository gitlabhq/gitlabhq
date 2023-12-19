import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/error_tracking/store/list/actions';
import * as types from '~/error_tracking/store/list/mutation_types';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/alert');

describe('error tracking actions', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('startPolling', () => {
    it('should start polling for data', () => {
      const payload = { errors: [{ id: 1 }, { id: 2 }] };

      mock.onGet().reply(HTTP_STATUS_OK, payload);
      return testAction(
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
      );
    });

    it('should show alert on API error', async () => {
      mock.onGet().reply(HTTP_STATUS_BAD_REQUEST);

      await testAction(
        actions.startPolling,
        {},
        {},
        [
          { type: types.SET_LOADING, payload: true },
          { type: types.SET_LOADING, payload: false },
        ],
        [],
      );
      expect(createAlert).toHaveBeenCalledTimes(1);
    });
  });

  describe('restartPolling', () => {
    it('should restart polling', () => {
      return testAction(
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

      return testAction(
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

      return testAction(
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

      return testAction(
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

      return testAction(
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
      return testAction(
        actions.fetchPaginatedResults,
        cursor,
        {},
        [{ type: types.SET_CURSOR, payload: cursor }],
        [{ type: 'stopPolling' }, { type: 'startPolling' }],
      );
    });
  });
});
