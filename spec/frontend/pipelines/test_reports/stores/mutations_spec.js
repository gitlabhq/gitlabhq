import * as types from '~/pipelines/stores/test_reports/mutation_types';
import mutations from '~/pipelines/stores/test_reports/mutations';
import { testReports, testSuites } from '../mock_data';

describe('Mutations TestReports Store', () => {
  let mockState;

  const defaultState = {
    endpoint: '',
    testReports: {},
    selectedSuite: {},
    isLoading: false,
  };

  beforeEach(() => {
    mockState = defaultState;
  });

  describe('set endpoint', () => {
    it('should set endpoint', () => {
      const expectedState = Object.assign({}, mockState, { endpoint: 'foo' });
      mutations[types.SET_ENDPOINT](mockState, 'foo');

      expect(mockState.endpoint).toEqual(expectedState.endpoint);
    });
  });

  describe('set reports', () => {
    it('should set testReports', () => {
      const expectedState = Object.assign({}, mockState, { testReports });
      mutations[types.SET_REPORTS](mockState, testReports);

      expect(mockState.testReports).toEqual(expectedState.testReports);
    });
  });

  describe('set selected suite', () => {
    it('should set selectedSuite', () => {
      const expectedState = Object.assign({}, mockState, { selectedSuite: testSuites[0] });
      mutations[types.SET_SELECTED_SUITE](mockState, testSuites[0]);

      expect(mockState.selectedSuite).toEqual(expectedState.selectedSuite);
    });
  });

  describe('toggle loading', () => {
    it('should set to true', () => {
      const expectedState = Object.assign({}, mockState, { isLoading: true });
      mutations[types.TOGGLE_LOADING](mockState);

      expect(mockState.isLoading).toEqual(expectedState.isLoading);
    });

    it('should toggle back to false', () => {
      const expectedState = Object.assign({}, mockState, { isLoading: false });
      mockState.isLoading = true;

      mutations[types.TOGGLE_LOADING](mockState);

      expect(mockState.isLoading).toEqual(expectedState.isLoading);
    });
  });
});
