import * as getters from '~/pipelines/stores/test_reports/getters';
import { testReports, testSuitesFormatted, testCasesFormatted } from '../mock_data';

describe('Getters TestReports Store', () => {
  let state;

  const defaultState = {
    testReports,
    selectedSuite: testReports.test_suites[0],
  };

  const emptyState = {
    testReports: {},
    selectedSuite: {},
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

      expect(getters.getTestSuites(state)).toEqual(testSuitesFormatted);
    });

    it('should return an empty array when testReports is empty', () => {
      setupState(emptyState);

      expect(getters.getTestSuites(state)).toEqual([]);
    });
  });

  describe('getSuiteTests', () => {
    it('should return the test cases inside the suite', () => {
      setupState();

      expect(getters.getSuiteTests(state)).toEqual(testCasesFormatted);
    });

    it('should return an empty array when testReports is empty', () => {
      setupState(emptyState);

      expect(getters.getSuiteTests(state)).toEqual([]);
    });
  });
});
