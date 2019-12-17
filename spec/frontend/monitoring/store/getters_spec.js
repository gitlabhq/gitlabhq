import * as getters from '~/monitoring/stores/getters';
import mutations from '~/monitoring/stores/mutations';
import * as types from '~/monitoring/stores/mutation_types';
import { metricStates } from '~/monitoring/constants';
import {
  metricsGroupsAPIResponse,
  mockedEmptyResult,
  mockedQueryResultPayload,
  mockedQueryResultPayloadCoresTotal,
} from '../mock_data';

describe('Monitoring store Getters', () => {
  describe('getMetricStates', () => {
    let setupState;
    let state;
    let getMetricStates;

    beforeEach(() => {
      setupState = (initState = {}) => {
        state = initState;
        getMetricStates = getters.getMetricStates(state);
      };
    });

    it('has method-style access', () => {
      setupState();

      expect(getMetricStates).toEqual(expect.any(Function));
    });

    it('when dashboard has no panel groups, returns empty', () => {
      setupState({
        dashboard: {
          panel_groups: [],
        },
      });

      expect(getMetricStates()).toEqual([]);
    });

    describe('when the dashboard is set', () => {
      let groups;
      beforeEach(() => {
        setupState({
          dashboard: { panel_groups: [] },
        });
        mutations[types.RECEIVE_METRICS_DATA_SUCCESS](state, metricsGroupsAPIResponse);
        groups = state.dashboard.panel_groups;
      });

      it('no loaded metric returns empty', () => {
        expect(getMetricStates()).toEqual([]);
      });

      it('on an empty metric with no result, returns NO_DATA', () => {
        mutations[types.RECEIVE_METRICS_DATA_SUCCESS](state, metricsGroupsAPIResponse);
        mutations[types.RECEIVE_METRIC_RESULT_SUCCESS](state, mockedEmptyResult);

        expect(getMetricStates()).toEqual([metricStates.NO_DATA]);
      });

      it('on a metric with a result, returns OK', () => {
        mutations[types.RECEIVE_METRICS_DATA_SUCCESS](state, metricsGroupsAPIResponse);
        mutations[types.RECEIVE_METRIC_RESULT_SUCCESS](state, mockedQueryResultPayload);

        expect(getMetricStates()).toEqual([metricStates.OK]);
      });

      it('on a metric with an error, returns an error', () => {
        mutations[types.RECEIVE_METRICS_DATA_SUCCESS](state, metricsGroupsAPIResponse);
        mutations[types.RECEIVE_METRIC_RESULT_FAILURE](state, {
          metricId: groups[0].panels[0].metrics[0].metricId,
        });

        expect(getMetricStates()).toEqual([metricStates.UNKNOWN_ERROR]);
      });

      it('on multiple metrics with results, returns OK', () => {
        mutations[types.RECEIVE_METRICS_DATA_SUCCESS](state, metricsGroupsAPIResponse);
        mutations[types.RECEIVE_METRIC_RESULT_SUCCESS](state, mockedQueryResultPayload);
        mutations[types.RECEIVE_METRIC_RESULT_SUCCESS](state, mockedQueryResultPayloadCoresTotal);

        expect(getMetricStates()).toEqual([metricStates.OK]);

        // Filtered by groups
        expect(getMetricStates(state.dashboard.panel_groups[0].key)).toEqual([]);
        expect(getMetricStates(state.dashboard.panel_groups[1].key)).toEqual([metricStates.OK]);
      });
      it('on multiple metrics errors', () => {
        mutations[types.RECEIVE_METRICS_DATA_SUCCESS](state, metricsGroupsAPIResponse);

        mutations[types.RECEIVE_METRIC_RESULT_FAILURE](state, {
          metricId: groups[0].panels[0].metrics[0].metricId,
        });
        mutations[types.RECEIVE_METRIC_RESULT_FAILURE](state, {
          metricId: groups[1].panels[0].metrics[0].metricId,
        });
        mutations[types.RECEIVE_METRIC_RESULT_FAILURE](state, {
          metricId: groups[1].panels[1].metrics[0].metricId,
        });

        // Entire dashboard fails
        expect(getMetricStates()).toEqual([metricStates.UNKNOWN_ERROR]);
        expect(getMetricStates(groups[0].key)).toEqual([metricStates.UNKNOWN_ERROR]);
        expect(getMetricStates(groups[1].key)).toEqual([metricStates.UNKNOWN_ERROR]);
      });

      it('on multiple metrics with errors', () => {
        mutations[types.RECEIVE_METRICS_DATA_SUCCESS](state, metricsGroupsAPIResponse);

        // An success in 1 group
        mutations[types.RECEIVE_METRIC_RESULT_SUCCESS](state, mockedQueryResultPayload);
        // An error in 2 groups
        mutations[types.RECEIVE_METRIC_RESULT_FAILURE](state, {
          metricId: groups[0].panels[0].metrics[0].metricId,
        });
        mutations[types.RECEIVE_METRIC_RESULT_FAILURE](state, {
          metricId: groups[1].panels[1].metrics[0].metricId,
        });

        expect(getMetricStates()).toEqual([metricStates.OK, metricStates.UNKNOWN_ERROR]);
        expect(getMetricStates(groups[0].key)).toEqual([metricStates.UNKNOWN_ERROR]);
        expect(getMetricStates(groups[1].key)).toEqual([
          metricStates.OK,
          metricStates.UNKNOWN_ERROR,
        ]);
      });
    });
  });

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
