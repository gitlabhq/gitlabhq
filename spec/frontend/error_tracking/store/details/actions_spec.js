import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/error_tracking/store/details/actions';
import * as types from '~/error_tracking/store/details/mutation_types';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_BAD_REQUEST,
  HTTP_STATUS_NO_CONTENT,
  HTTP_STATUS_OK,
} from '~/lib/utils/http_status';
import Poll from '~/lib/utils/poll';

let mockedAdapter;
let mockedRestart;

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility');

describe('Sentry error details store actions', () => {
  beforeEach(() => {
    mockedAdapter = new MockAdapter(axios);
  });

  afterEach(() => {
    mockedAdapter.restore();
    createAlert.mockClear();
    if (mockedRestart) {
      mockedRestart.mockRestore();
      mockedRestart = null;
    }
  });

  describe('startPollingStacktrace', () => {
    const endpoint = '123/stacktrace';
    it('should commit SET_ERROR with received response', () => {
      const payload = { error: [1, 2, 3] };
      mockedAdapter.onGet().reply(HTTP_STATUS_OK, payload);
      return testAction(
        actions.startPollingStacktrace,
        { endpoint },
        {},
        [
          { type: types.SET_STACKTRACE_DATA, payload: payload.error },
          { type: types.SET_LOADING_STACKTRACE, payload: false },
        ],
        [],
      );
    });

    it('should show alert on API error', async () => {
      mockedAdapter.onGet().reply(HTTP_STATUS_BAD_REQUEST);

      await testAction(
        actions.startPollingStacktrace,
        { endpoint },
        {},
        [{ type: types.SET_LOADING_STACKTRACE, payload: false }],
        [],
      );
      expect(createAlert).toHaveBeenCalledTimes(1);
    });

    it('should not restart polling when receiving an empty 204 response', async () => {
      mockedRestart = jest.spyOn(Poll.prototype, 'restart');
      mockedAdapter.onGet().reply(HTTP_STATUS_NO_CONTENT);

      await testAction(actions.startPollingStacktrace, { endpoint }, {}, [], []);
      mockedRestart = jest.spyOn(Poll.prototype, 'restart');
      expect(mockedRestart).toHaveBeenCalledTimes(0);
    });
  });
});
