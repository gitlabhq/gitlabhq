import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import * as actions from '~/related_merge_requests/store/actions';
import * as types from '~/related_merge_requests/store/mutation_types';

jest.mock('~/flash');

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
    it('commits types.SET_INITIAL_STATE with given props', (done) => {
      const props = { a: 1, b: 2 };

      testAction(
        actions.setInitialState,
        props,
        {},
        [{ type: types.SET_INITIAL_STATE, payload: props }],
        [],
        done,
      );
    });
  });

  describe('requestData', () => {
    it('commits types.REQUEST_DATA', (done) => {
      testAction(actions.requestData, null, {}, [{ type: types.REQUEST_DATA }], [], done);
    });
  });

  describe('receiveDataSuccess', () => {
    it('commits types.RECEIVE_DATA_SUCCESS with data', (done) => {
      const data = { a: 1, b: 2 };

      testAction(
        actions.receiveDataSuccess,
        data,
        {},
        [{ type: types.RECEIVE_DATA_SUCCESS, payload: data }],
        [],
        done,
      );
    });
  });

  describe('receiveDataError', () => {
    it('commits types.RECEIVE_DATA_ERROR', (done) => {
      testAction(
        actions.receiveDataError,
        null,
        {},
        [{ type: types.RECEIVE_DATA_ERROR }],
        [],
        done,
      );
    });
  });

  describe('fetchMergeRequests', () => {
    describe('for a successful request', () => {
      it('should dispatch success action', (done) => {
        const data = { a: 1 };
        mock.onGet(`${state.apiEndpoint}?per_page=100`).replyOnce(200, data, { 'x-total': 2 });

        testAction(
          actions.fetchMergeRequests,
          null,
          state,
          [],
          [{ type: 'requestData' }, { type: 'receiveDataSuccess', payload: { data, total: 2 } }],
          done,
        );
      });
    });

    describe('for a failing request', () => {
      it('should dispatch error action', (done) => {
        mock.onGet(`${state.apiEndpoint}?per_page=100`).replyOnce(400);

        testAction(
          actions.fetchMergeRequests,
          null,
          state,
          [],
          [{ type: 'requestData' }, { type: 'receiveDataError' }],
          () => {
            expect(createFlash).toHaveBeenCalledTimes(1);
            expect(createFlash).toHaveBeenCalledWith({
              message: expect.stringMatching('Something went wrong'),
            });

            done();
          },
        );
      });
    });
  });
});
