import { getJSONFixture } from 'helpers/fixtures';
import * as getters from '~/pipelines/stores/test_reports/getters';
import { iconForTestStatus } from '~/pipelines/stores/test_reports/utils';

describe('Getters TestReports Store', () => {
  let state;

  const testReports = getJSONFixture('pipelines/test_report.json');

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

      const suites = getters.getTestSuites(state);
      const expected = testReports.test_suites.map(x => ({
        ...x,
        formattedTime: '00:00:00',
      }));

      expect(suites).toEqual(expected);
    });

    it('should return an empty array when testReports is empty', () => {
      setupState(emptyState);

      expect(getters.getTestSuites(state)).toEqual([]);
    });
  });

  describe('getSuiteTests', () => {
    it('should return the test cases inside the suite', () => {
      setupState();

      const cases = getters.getSuiteTests(state);
      const expected = testReports.test_suites[0].test_cases.map(x => ({
        ...x,
        formattedTime: '00:00:00',
        icon: iconForTestStatus(x.status),
      }));

      expect(cases).toEqual(expected);
    });

    it('should return an empty array when testReports is empty', () => {
      setupState(emptyState);

      expect(getters.getSuiteTests(state)).toEqual([]);
    });
  });
});
