import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/admin/statistics_panel/store/actions';
import * as types from '~/admin/statistics_panel/store/mutation_types';
import getInitialState from '~/admin/statistics_panel/store/state';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import mockStatistics from '../mock_data';

describe('Admin statistics panel actions', () => {
  let mock;
  let state;

  beforeEach(() => {
    state = getInitialState();
    mock = new MockAdapter(axios);
  });

  describe('fetchStatistics', () => {
    describe('success', () => {
      beforeEach(() => {
        mock.onGet(/api\/(.*)\/application\/statistics/).replyOnce(HTTP_STATUS_OK, mockStatistics);
      });

      it('dispatches success with received data', () => {
        return testAction(
          actions.fetchStatistics,
          null,
          state,
          [],
          [
            { type: 'requestStatistics' },
            {
              type: 'receiveStatisticsSuccess',
              payload: expect.objectContaining(
                convertObjectPropsToCamelCase(mockStatistics, { deep: true }),
              ),
            },
          ],
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock
          .onGet(/api\/(.*)\/application\/statistics/)
          .replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      });

      it('dispatches error', () => {
        return testAction(
          actions.fetchStatistics,
          null,
          state,
          [],
          [
            {
              type: 'requestStatistics',
            },
            {
              type: 'receiveStatisticsError',
              payload: new Error('Request failed with status code 500'),
            },
          ],
        );
      });
    });
  });

  describe('requestStatistic', () => {
    it('should commit the request mutation', () => {
      return testAction(
        actions.requestStatistics,
        null,
        state,
        [{ type: types.REQUEST_STATISTICS }],
        [],
      );
    });
  });

  describe('receiveStatisticsSuccess', () => {
    it('should commit received data', () => {
      return testAction(
        actions.receiveStatisticsSuccess,
        mockStatistics,
        state,
        [
          {
            type: types.RECEIVE_STATISTICS_SUCCESS,
            payload: mockStatistics,
          },
        ],
        [],
      );
    });
  });

  describe('receiveStatisticsError', () => {
    it('should commit error', () => {
      return testAction(
        actions.receiveStatisticsError,
        HTTP_STATUS_INTERNAL_SERVER_ERROR,
        state,
        [
          {
            type: types.RECEIVE_STATISTICS_ERROR,
            payload: HTTP_STATUS_INTERNAL_SERVER_ERROR,
          },
        ],
        [],
      );
    });
  });
});
