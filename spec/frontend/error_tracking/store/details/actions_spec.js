import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import * as actions from '~/error_tracking/store/details/actions';
import * as types from '~/error_tracking/store/details/mutation_types';

jest.mock('~/flash.js');
let mock;

describe('Sentry error details store actions', () => {
  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    createFlash.mockClear();
  });

  describe('startPollingDetails', () => {
    const endpoint = '123/details';
    it('should commit SET_ERROR with received response', done => {
      const payload = { error: { id: 1 } };
      mock.onGet().reply(200, payload);
      testAction(
        actions.startPollingDetails,
        { endpoint },
        {},
        [
          { type: types.SET_ERROR, payload: payload.error },
          { type: types.SET_LOADING, payload: false },
        ],
        [],
        () => {
          done();
        },
      );
    });

    it('should show flash on API error', done => {
      mock.onGet().reply(400);

      testAction(
        actions.startPollingDetails,
        { endpoint },
        {},
        [{ type: types.SET_LOADING, payload: false }],
        [],
        () => {
          expect(createFlash).toHaveBeenCalledTimes(1);
          done();
        },
      );
    });
  });

  describe('startPollingStacktrace', () => {
    const endpoint = '123/stacktrace';
    it('should commit SET_ERROR with received response', done => {
      const payload = { error: [1, 2, 3] };
      mock.onGet().reply(200, payload);
      testAction(
        actions.startPollingStacktrace,
        { endpoint },
        {},
        [
          { type: types.SET_STACKTRACE_DATA, payload: payload.error },
          { type: types.SET_LOADING_STACKTRACE, payload: false },
        ],
        [],
        () => {
          done();
        },
      );
    });

    it('should show flash on API error', done => {
      mock.onGet().reply(400);

      testAction(
        actions.startPollingStacktrace,
        { endpoint },
        {},
        [{ type: types.SET_LOADING_STACKTRACE, payload: false }],
        [],
        () => {
          expect(createFlash).toHaveBeenCalledTimes(1);
          done();
        },
      );
    });
  });
});
