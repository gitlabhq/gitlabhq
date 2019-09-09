import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import * as actions from '~/admin/statistics_panel/store/actions';
import * as types from '~/admin/statistics_panel/store/mutation_types';
import getInitialState from '~/admin/statistics_panel/store/state';
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
        mock.onGet(/api\/(.*)\/application\/statistics/).replyOnce(200, mockStatistics);
      });

      it('dispatches success with received data', done =>
        testAction(
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
          done,
        ));
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/api\/(.*)\/application\/statistics/).replyOnce(500);
      });

      it('dispatches error', done =>
        testAction(
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
          done,
        ));
    });
  });

  describe('requestStatistic', () => {
    it('should commit the request mutation', done =>
      testAction(
        actions.requestStatistics,
        null,
        state,
        [{ type: types.REQUEST_STATISTICS }],
        [],
        done,
      ));
  });

  describe('receiveStatisticsSuccess', () => {
    it('should commit received data', done =>
      testAction(
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
        done,
      ));
  });

  describe('receiveStatisticsError', () => {
    it('should commit error', done => {
      testAction(
        actions.receiveStatisticsError,
        500,
        state,
        [
          {
            type: types.RECEIVE_STATISTICS_ERROR,
            payload: 500,
          },
        ],
        [],
        done,
      );
    });
  });
});
