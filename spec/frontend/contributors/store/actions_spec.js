import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import flashError from '~/flash';
import * as actions from '~/contributors/stores/actions';
import * as types from '~/contributors/stores/mutation_types';

jest.mock('~/flash.js');

describe('Contributors store actions', () => {
  describe('fetchChartData', () => {
    let mock;
    const endpoint = '/contributors';
    const chartData = { '2017-11': 0, '2017-12': 2 };

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    it('should commit SET_CHART_DATA with received response', done => {
      mock.onGet().reply(200, chartData);

      testAction(
        actions.fetchChartData,
        { endpoint },
        {},
        [
          { type: types.SET_LOADING_STATE, payload: true },
          { type: types.SET_CHART_DATA, payload: chartData },
          { type: types.SET_LOADING_STATE, payload: false },
        ],
        [],
        () => {
          mock.restore();
          done();
        },
      );
    });

    it('should show flash on API error', done => {
      mock.onGet().reply(400, 'Not Found');

      testAction(
        actions.fetchChartData,
        { endpoint },
        {},
        [{ type: types.SET_LOADING_STATE, payload: true }],
        [],
        () => {
          expect(flashError).toHaveBeenCalledWith(expect.stringMatching('error'));
          mock.restore();
          done();
        },
      );
    });
  });
});

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
