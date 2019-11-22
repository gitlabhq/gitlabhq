import * as types from '~/pipelines/stores/test_reports/mutation_types';
import mutations from '~/pipelines/stores/test_reports/mutations';
import { getJSONFixture } from 'helpers/fixtures';

describe('Mutations TestReports Store', () => {
  let mockState;

  const testReports = getJSONFixture('pipelines/test_report.json');

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
      const expectedState = { ...mockState, testReports };
      mutations[types.SET_REPORTS](mockState, testReports);

      expect(mockState.testReports).toEqual(expectedState.testReports);
    });
  });

  describe('set selected suite', () => {
    it('should set selectedSuite', () => {
      const selectedSuite = testReports.test_suites[0];
      mutations[types.SET_SELECTED_SUITE](mockState, selectedSuite);

      expect(mockState.selectedSuite).toEqual(selectedSuite);
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
