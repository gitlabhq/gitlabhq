import serverlessState from '~/serverless/store/state';
import * as getters from '~/serverless/store/getters';
import { mockServerlessFunctions } from '../mock_data';

describe('Serverless Store Getters', () => {
  let state;

  beforeEach(() => {
    state = serverlessState;
  });

  describe('hasPrometheusMissingData', () => {
    it('should return false if Prometheus is not installed', () => {
      state.hasPrometheus = false;

      expect(getters.hasPrometheusMissingData(state)).toEqual(false);
    });

    it('should return false if Prometheus is installed and there is data', () => {
      state.hasPrometheusData = true;

      expect(getters.hasPrometheusMissingData(state)).toEqual(false);
    });

    it('should return true if Prometheus is installed and there is no data', () => {
      state.hasPrometheus = true;
      state.hasPrometheusData = false;

      expect(getters.hasPrometheusMissingData(state)).toEqual(true);
    });
  });

  describe('getFunctions', () => {
    it('should translate the raw function array to group the functions per environment scope', () => {
      state.functions = mockServerlessFunctions.functions;

      const funcs = getters.getFunctions(state);

      expect(Object.keys(funcs)).toContain('*');
      expect(funcs['*'].length).toEqual(2);
    });
  });
});
