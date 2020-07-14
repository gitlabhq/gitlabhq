import { getJSONFixture } from 'helpers/fixtures';
import * as types from '~/pipelines/stores/test_reports/mutation_types';
import mutations from '~/pipelines/stores/test_reports/mutations';

describe('Mutations TestReports Store', () => {
  let mockState;

  const testReports = getJSONFixture('pipelines/test_report.json');

  const defaultState = {
    endpoint: '',
    testReports: {},
    selectedSuite: null,
    isLoading: false,
    hasFullReport: false,
  };

  beforeEach(() => {
    mockState = { ...defaultState };
  });

  describe('set reports', () => {
    it('should set testReports', () => {
      const expectedState = { ...mockState, testReports };
      mutations[types.SET_REPORTS](mockState, testReports);

      expect(mockState.testReports).toEqual(expectedState.testReports);
      expect(mockState.hasFullReport).toBe(true);
    });
  });

  describe('set selected suite index', () => {
    it('should set selectedSuiteIndex', () => {
      const selectedSuiteIndex = 0;
      mutations[types.SET_SELECTED_SUITE_INDEX](mockState, selectedSuiteIndex);

      expect(mockState.selectedSuiteIndex).toEqual(selectedSuiteIndex);
    });
  });

  describe('set summary', () => {
    it('should set summary', () => {
      const summary = { total_count: 1 };
      mutations[types.SET_SUMMARY](mockState, summary);

      expect(mockState.testReports).toEqual(summary);
    });
  });

  describe('toggle loading', () => {
    it('should set to true', () => {
      const expectedState = { ...mockState, isLoading: true };
      mutations[types.TOGGLE_LOADING](mockState);

      expect(mockState.isLoading).toEqual(expectedState.isLoading);
    });

    it('should toggle back to false', () => {
      const expectedState = { ...mockState, isLoading: false };
      mockState.isLoading = true;

      mutations[types.TOGGLE_LOADING](mockState);

      expect(mockState.isLoading).toEqual(expectedState.isLoading);
    });
  });
});
