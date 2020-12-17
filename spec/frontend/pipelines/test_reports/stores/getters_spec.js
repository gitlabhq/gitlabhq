import { getJSONFixture } from 'helpers/fixtures';
import * as getters from '~/pipelines/stores/test_reports/getters';
import { iconForTestStatus, formattedTime } from '~/pipelines/stores/test_reports/utils';

describe('Getters TestReports Store', () => {
  let state;

  const testReports = getJSONFixture('pipelines/test_report.json');

  const defaultState = {
    testReports,
    selectedSuiteIndex: 0,
    pageInfo: {
      page: 1,
      perPage: 2,
    },
  };

  const emptyState = {
    testReports: {},
    selectedSuite: null,
    pageInfo: {
      page: 1,
      perPage: 2,
    },
  };

  beforeEach(() => {
    state = {
      testReports,
    };
  });

  const setupState = (testState = defaultState) => {
    state = testState;
  };

  describe('getTestSuites', () => {
    it('should return the test suites', () => {
      setupState();

      const suites = getters.getTestSuites(state);
      const expected = testReports.test_suites.map(x => ({
        ...x,
        formattedTime: formattedTime(x.total_time),
      }));

      expect(suites).toEqual(expected);
    });

    it('should return an empty array when testReports is empty', () => {
      setupState(emptyState);

      expect(getters.getTestSuites(state)).toEqual([]);
    });
  });

  describe('getSelectedSuite', () => {
    it('should return the selected suite', () => {
      setupState();

      const selectedSuite = getters.getSelectedSuite(state);
      const expected = testReports.test_suites[state.selectedSuiteIndex];

      expect(selectedSuite).toEqual(expected);
    });
  });

  describe('getSuiteTests', () => {
    it('should return the current page of test cases inside the suite', () => {
      setupState();

      const cases = getters.getSuiteTests(state);
      const expected = testReports.test_suites[0].test_cases
        .map(x => ({
          ...x,
          formattedTime: formattedTime(x.execution_time),
          icon: iconForTestStatus(x.status),
        }))
        .slice(0, state.pageInfo.perPage);

      expect(cases).toEqual(expected);
    });

    it('should return an empty array when testReports is empty', () => {
      setupState(emptyState);

      expect(getters.getSuiteTests(state)).toEqual([]);
    });
  });

  describe('getSuiteTestCount', () => {
    it('should return the total number of test cases', () => {
      setupState();

      const testCount = getters.getSuiteTestCount(state);
      const expected = testReports.test_suites[0].test_cases.length;

      expect(testCount).toEqual(expected);
    });
  });
});
