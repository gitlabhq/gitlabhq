import testReports from 'test_fixtures/pipelines/test_report.json';
import * as getters from '~/ci/pipeline_details/stores/test_reports/getters';
import {
  iconForTestStatus,
  formatFilePath,
  formattedTime,
} from '~/ci/pipeline_details/stores/test_reports/utils';

describe('Getters TestReports Store', () => {
  let state;

  const defaultState = {
    blobPath: '/test/blob/path',
    testReports,
    selectedSuiteIndex: 0,
    pageInfo: {
      page: 1,
      perPage: 2,
    },
  };

  const emptyState = {
    blobPath: '',
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
      const expected = testReports.test_suites.map((x) => ({
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
        .map((x) => ({
          ...x,
          filePath: `${state.blobPath}/${formatFilePath(x.file)}`,
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

    describe('when a test case classname property is null', () => {
      it('should return an empty string value for the classname property', () => {
        const testCases = testReports.test_suites[0].test_cases;
        setupState({
          ...defaultState,
          testReports: {
            ...testReports,
            test_suites: [
              {
                test_cases: testCases.map((testCase) => ({
                  ...testCase,
                  classname: null,
                })),
              },
            ],
          },
        });

        const expected = testCases
          .map((x) => ({
            ...x,
            classname: '',
            filePath: `${state.blobPath}/${formatFilePath(x.file)}`,
            formattedTime: formattedTime(x.execution_time),
            icon: iconForTestStatus(x.status),
          }))
          .slice(0, state.pageInfo.perPage);

        expect(getters.getSuiteTests(state)).toEqual(expected);
      });
    });

    describe('when a test case name property is null', () => {
      it('should return an empty string value for the name property', () => {
        const testCases = testReports.test_suites[0].test_cases;
        setupState({
          ...defaultState,
          testReports: {
            ...testReports,
            test_suites: [
              {
                test_cases: testCases.map((testCase) => ({
                  ...testCase,
                  name: null,
                })),
              },
            ],
          },
        });

        const expected = testCases
          .map((x) => ({
            ...x,
            name: '',
            filePath: `${state.blobPath}/${formatFilePath(x.file)}`,
            formattedTime: formattedTime(x.execution_time),
            icon: iconForTestStatus(x.status),
          }))
          .slice(0, state.pageInfo.perPage);

        expect(getters.getSuiteTests(state)).toEqual(expected);
      });
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
