import * as types from '~/serverless/store/mutation_types';
import mutations from '~/serverless/store/mutations';
import { mockServerlessFunctions, mockMetrics } from '../mock_data';

describe('ServerlessMutations', () => {
  describe('Functions List Mutations', () => {
    it('should ensure loading is true', () => {
      const state = {};

      mutations[types.REQUEST_FUNCTIONS_LOADING](state);

      expect(state.isLoading).toEqual(true);
    });

    it('should set proper state once functions are loaded', () => {
      const state = {};

      mutations[types.RECEIVE_FUNCTIONS_SUCCESS](state, mockServerlessFunctions);

      expect(state.isLoading).toEqual(false);
      expect(state.hasFunctionData).toEqual(true);
      expect(state.functions).toEqual(mockServerlessFunctions.functions);
    });

    it('should ensure loading has stopped and hasFunctionData is false when there are no functions available', () => {
      const state = {};

      mutations[types.RECEIVE_FUNCTIONS_NODATA_SUCCESS](state, { knative_installed: true });

      expect(state.isLoading).toEqual(false);
      expect(state.hasFunctionData).toEqual(false);
      expect(state.functions).toBe(undefined);
    });

    it('should ensure loading has stopped, and an error is raised', () => {
      const state = {};

      mutations[types.RECEIVE_FUNCTIONS_ERROR](state, 'sample error');

      expect(state.isLoading).toEqual(false);
      expect(state.hasFunctionData).toEqual(false);
      expect(state.functions).toBe(undefined);
      expect(state.error).not.toBe(undefined);
    });
  });

  describe('Function Details Metrics Mutations', () => {
    it('should ensure isLoading and hasPrometheus data flags indicate data is loaded', () => {
      const state = {};

      mutations[types.RECEIVE_METRICS_SUCCESS](state, mockMetrics);

      expect(state.isLoading).toEqual(false);
      expect(state.hasPrometheusData).toEqual(true);
      expect(state.graphData).toEqual(mockMetrics);
    });

    it('should ensure isLoading and hasPrometheus data flags are cleared indicating no functions available', () => {
      const state = {};

      mutations[types.RECEIVE_METRICS_NODATA_SUCCESS](state);

      expect(state.isLoading).toEqual(false);
      expect(state.hasPrometheusData).toEqual(false);
      expect(state.graphData).toBe(undefined);
    });

    it('should properly indicate an error', () => {
      const state = {};

      mutations[types.RECEIVE_METRICS_ERROR](state, 'sample error');

      expect(state.hasPrometheusData).toEqual(false);
      expect(state.error).not.toBe(undefined);
    });

    it('should properly indicate when prometheus is installed', () => {
      const state = {};

      mutations[types.RECEIVE_METRICS_NO_PROMETHEUS](state);

      expect(state.hasPrometheus).toEqual(false);
      expect(state.hasPrometheusData).toEqual(false);
    });
  });
});
