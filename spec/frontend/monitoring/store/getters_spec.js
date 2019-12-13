import * as getters from '~/monitoring/stores/getters';

import mutations from '~/monitoring/stores/mutations';
import * as types from '~/monitoring/stores/mutation_types';
import {
  metricsGroupsAPIResponse,
  mockedEmptyResult,
  mockedQueryResultPayload,
  mockedQueryResultPayloadCoresTotal,
} from '../mock_data';

describe('Monitoring store Getters', () => {
  describe('metricsWithData', () => {
    let metricsWithData;
    let setupState;
    let state;

    beforeEach(() => {
      setupState = (initState = {}) => {
        state = initState;
        metricsWithData = getters.metricsWithData(state);
      };
    });

    afterEach(() => {
      state = null;
    });

    it('has method-style access', () => {
      setupState();

      expect(metricsWithData).toEqual(expect.any(Function));
    });

    it('when dashboard has no panel groups, returns empty', () => {
      setupState({
        dashboard: {
          panel_groups: [],
        },
      });

      expect(metricsWithData()).toEqual([]);
    });

    describe('when the dashboard is set', () => {
      beforeEach(() => {
        setupState({
          dashboard: { panel_groups: [] },
        });
      });

      it('no loaded metric returns empty', () => {
        mutations[types.RECEIVE_METRICS_DATA_SUCCESS](state, metricsGroupsAPIResponse);

        expect(metricsWithData()).toEqual([]);
      });

      it('an empty metric, returns empty', () => {
        mutations[types.RECEIVE_METRICS_DATA_SUCCESS](state, metricsGroupsAPIResponse);
        mutations[types.RECEIVE_METRIC_RESULT_SUCCESS](state, mockedEmptyResult);

        expect(metricsWithData()).toEqual([]);
      });

      it('a metric with results, it returns a metric', () => {
        mutations[types.RECEIVE_METRICS_DATA_SUCCESS](state, metricsGroupsAPIResponse);
        mutations[types.RECEIVE_METRIC_RESULT_SUCCESS](state, mockedQueryResultPayload);

        expect(metricsWithData()).toEqual([mockedQueryResultPayload.metricId]);
      });

      it('multiple metrics with results, it return multiple metrics', () => {
        mutations[types.RECEIVE_METRICS_DATA_SUCCESS](state, metricsGroupsAPIResponse);
        mutations[types.RECEIVE_METRIC_RESULT_SUCCESS](state, mockedQueryResultPayload);
        mutations[types.RECEIVE_METRIC_RESULT_SUCCESS](state, mockedQueryResultPayloadCoresTotal);

        expect(metricsWithData()).toEqual([
          mockedQueryResultPayload.metricId,
          mockedQueryResultPayloadCoresTotal.metricId,
        ]);
      });

      it('multiple metrics with results, it returns metrics filtered by group', () => {
        mutations[types.RECEIVE_METRICS_DATA_SUCCESS](state, metricsGroupsAPIResponse);
        mutations[types.RECEIVE_METRIC_RESULT_SUCCESS](state, mockedQueryResultPayload);
        mutations[types.RECEIVE_METRIC_RESULT_SUCCESS](state, mockedQueryResultPayloadCoresTotal);

        // First group has no metrics
        expect(metricsWithData(state.dashboard.panel_groups[0].key)).toEqual([]);

        // Second group has metrics
        expect(metricsWithData(state.dashboard.panel_groups[1].key)).toEqual([
          mockedQueryResultPayload.metricId,
          mockedQueryResultPayloadCoresTotal.metricId,
        ]);
      });
    });
  });
});
