import testReports from 'test_fixtures/pipelines/test_report.json';
import * as types from '~/ci/pipeline_details/stores/test_reports/mutation_types';
import mutations from '~/ci/pipeline_details/stores/test_reports/mutations';
import { createAlert } from '~/alert';

jest.mock('~/alert');

describe('Mutations TestReports Store', () => {
  let mockState;

  const defaultState = {
    endpoint: '',
    testReports: {},
    selectedSuite: null,
    isLoading: false,
    pageInfo: {
      page: 1,
      perPage: 2,
    },
  };

  beforeEach(() => {
    mockState = { ...defaultState };
  });

  describe('set page', () => {
    it('should set the current page to display', () => {
      const pageToDisplay = 3;
      mutations[types.SET_PAGE](mockState, pageToDisplay);

      expect(mockState.pageInfo.page).toEqual(pageToDisplay);
    });
  });

  describe('set suite', () => {
    it('should set the suite at the given index', () => {
      mockState.testReports = testReports;
      const suite = { name: 'test_suite' };
      const index = 0;
      const expectedState = { ...mockState };
      expectedState.testReports.test_suites[index] = { suite, hasFullSuite: true };
      mutations[types.SET_SUITE](mockState, { suite, index });

      expect(mockState.testReports.test_suites[index]).toEqual(
        expectedState.testReports.test_suites[index],
      );
    });
  });

  describe('set suite error', () => {
    it('should set the error message in state if provided', () => {
      const message = 'Test report artifacts not found';

      mutations[types.SET_SUITE_ERROR](mockState, {
        response: { data: { errors: message } },
      });

      expect(mockState.errorMessage).toBe(message);
    });

    it('should show an alert otherwise', () => {
      mutations[types.SET_SUITE_ERROR](mockState, {});

      expect(createAlert).toHaveBeenCalled();
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
      const summary = {
        total: { time: 0, count: 10, success: 1, failed: 2, skipped: 3, error: 4 },
      };
      const expectedSummary = {
        ...summary,
        total_time: 0,
        total_count: 10,
        success_count: 1,
        failed_count: 2,
        skipped_count: 3,
        error_count: 4,
      };
      mutations[types.SET_SUMMARY](mockState, summary);

      expect(mockState.testReports).toEqual(expectedSummary);
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
