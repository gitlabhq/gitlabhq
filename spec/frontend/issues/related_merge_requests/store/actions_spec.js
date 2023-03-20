import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import * as actions from '~/issues/related_merge_requests/store/actions';
import * as types from '~/issues/related_merge_requests/store/mutation_types';

jest.mock('~/alert');

describe('RelatedMergeRequest store actions', () => {
  let state;
  let mock;

  beforeEach(() => {
    state = {
      apiEndpoint: '/api/related_merge_requests',
    };
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('setInitialState', () => {
    it('commits types.SET_INITIAL_STATE with given props', () => {
      const props = { a: 1, b: 2 };

      return testAction(
        actions.setInitialState,
        props,
        {},
        [{ type: types.SET_INITIAL_STATE, payload: props }],
        [],
      );
    });
  });

  describe('requestData', () => {
    it('commits types.REQUEST_DATA', () => {
      return testAction(actions.requestData, null, {}, [{ type: types.REQUEST_DATA }], []);
    });
  });

  describe('receiveDataSuccess', () => {
    it('commits types.RECEIVE_DATA_SUCCESS with data', () => {
      const data = { a: 1, b: 2 };

      return testAction(
        actions.receiveDataSuccess,
        data,
        {},
        [{ type: types.RECEIVE_DATA_SUCCESS, payload: data }],
        [],
      );
    });
  });

  describe('receiveDataError', () => {
    it('commits types.RECEIVE_DATA_ERROR', () => {
      return testAction(
        actions.receiveDataError,
        null,
        {},
        [{ type: types.RECEIVE_DATA_ERROR }],
        [],
      );
    });
  });

  describe('fetchMergeRequests', () => {
    describe('for a successful request', () => {
      it('should dispatch success action', () => {
        const data = { a: 1 };
        mock
          .onGet(`${state.apiEndpoint}?per_page=100`)
          .replyOnce(HTTP_STATUS_OK, data, { 'x-total': 2 });

        return testAction(
          actions.fetchMergeRequests,
          null,
          state,
          [],
          [{ type: 'requestData' }, { type: 'receiveDataSuccess', payload: { data, total: 2 } }],
        );
      });
    });

    describe('for a failing request', () => {
      it('should dispatch error action', async () => {
        mock.onGet(`${state.apiEndpoint}?per_page=100`).replyOnce(HTTP_STATUS_BAD_REQUEST);

        await testAction(
          actions.fetchMergeRequests,
          null,
          state,
          [],
          [{ type: 'requestData' }, { type: 'receiveDataError' }],
        );
        expect(createAlert).toHaveBeenCalledTimes(1);
        expect(createAlert).toHaveBeenCalledWith({
          message: expect.stringMatching('Something went wrong'),
        });
      });
    });
  });
});
