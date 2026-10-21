import testReports from 'test_fixtures/pipelines/test_report.json';
import * as getters from '~/ci/pipeline_details/stores/test_reports/getters';
import {
  iconForTestStatus,
  formatFilePath,
  formattedTime,
} from '~/ci/pipeline_details/stores/test_reports/utils';
import {
  ARTIFACTS_EXPIRED_ERROR_MESSAGE,
  SEARCH_SCOPE_SUITE,
  SEARCH_SCOPE_ALL,
} from '~/ci/pipeline_details/stores/test_reports/constants';

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
    it('returns the test suites', () => {
      setupState();

      const suites = getters.getTestSuites(state);
      const expected = testReports.test_suites.map((x) => ({
        ...x,
        formattedTime: formattedTime(x.total_time),
      }));

      expect(suites).toEqual(expected);
    });

    describe('when testReports is empty', () => {
      it('returns an empty array', () => {
        setupState(emptyState);

        expect(getters.getTestSuites(state)).toEqual([]);
      });
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

    describe('when testReports is empty', () => {
      it('returns an empty array', () => {
        setupState(emptyState);

        expect(getters.getSuiteTests(state)).toEqual([]);
      });
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

  describe('getSuiteArtifactsExpired', () => {
    describe('when errorMessage matches the artifacts-expired message', () => {
      it('returns true', () => {
        setupState({ ...defaultState, errorMessage: ARTIFACTS_EXPIRED_ERROR_MESSAGE });

        expect(getters.getSuiteArtifactsExpired(state)).toBe(true);
      });
    });

    describe('when errorMessage does not match the artifacts-expired message', () => {
      it('returns false', () => {
        setupState({ ...defaultState, errorMessage: null });

        expect(getters.getSuiteArtifactsExpired(state)).toBe(false);
      });
    });
  });

  describe('getTotalSuiteCount', () => {
    it('returns the number of suites in the pipeline', () => {
      setupState();

      expect(getters.getTotalSuiteCount(state)).toBe(testReports.test_suites.length);
    });

    describe('when testReports is empty', () => {
      it('returns 0', () => {
        setupState(emptyState);

        expect(getters.getTotalSuiteCount(state)).toBe(0);
      });
    });
  });

  describe('isSearching', () => {
    describe('when searchTerm is empty', () => {
      it('returns false', () => {
        setupState({ ...defaultState, searchTerm: '' });

        expect(getters.isSearching(state)).toBe(false);
      });
    });

    describe('when searchTerm is only whitespace', () => {
      it('returns false', () => {
        setupState({ ...defaultState, searchTerm: '   ' });

        expect(getters.isSearching(state)).toBe(false);
      });
    });

    describe('when searchTerm has content', () => {
      it('returns true', () => {
        setupState({ ...defaultState, searchTerm: 'test' });

        expect(getters.isSearching(state)).toBe(true);
      });
    });
  });

  describe('getAllTestCases', () => {
    it("should flatten every suite's test cases and tag each with its suite name", () => {
      setupState();

      const cases = getters.getAllTestCases(state);
      const expected = testReports.test_suites.flatMap((suite) =>
        suite.test_cases.map((testCase) => ({
          ...testCase,
          classname: testCase.classname || '',
          name: testCase.name || '',
          suiteName: suite.name,
          filePath: `${state.blobPath}/${formatFilePath(testCase.file)}`,
        })),
      );

      expect(cases).toEqual(expected);
    });

    describe('when testReports is empty', () => {
      it('returns an empty array', () => {
        setupState(emptyState);

        expect(getters.getAllTestCases(state)).toEqual([]);
      });
    });
  });

  describe('getFilteredTestCases', () => {
    const getMockGetters = () => ({
      getAllTestCases: getters.getAllTestCases(state),
    });

    describe('when search scope is "all"', () => {
      it('searches across every suite', () => {
        setupState({ ...defaultState, searchScope: SEARCH_SCOPE_ALL, searchTerm: '' });

        expect(getters.getFilteredTestCases(state, getMockGetters())).toEqual(
          getters.getAllTestCases(state),
        );
      });
    });

    describe('when search scope is "suite"', () => {
      it('limits results to the selected suite', () => {
        setupState({
          ...defaultState,
          searchScope: SEARCH_SCOPE_SUITE,
          selectedSuiteIndex: 0,
          searchTerm: '',
        });

        const expected = getters
          .getAllTestCases(state)
          .filter((testCase) => testCase.suiteName === testReports.test_suites[0].name);

        expect(getters.getFilteredTestCases(state, getMockGetters())).toEqual(expected);
      });
    });

    describe('when search term is provided', () => {
      it('filters by the search term', () => {
        const [firstCase] = testReports.test_suites[0].test_cases;
        setupState({
          ...defaultState,
          searchScope: SEARCH_SCOPE_ALL,
          searchTerm: firstCase.name,
        });

        const expected = getters
          .getAllTestCases(state)
          .filter((testCase) => testCase.name === firstCase.name);

        expect(getters.getFilteredTestCases(state, getMockGetters())).toEqual(expected);
      });
    });
  });

  describe('getSearchResults', () => {
    it('should paginate the filtered test cases and add icon/time metadata', () => {
      setupState({ ...defaultState, searchScope: SEARCH_SCOPE_ALL, searchTerm: '' });
      const mockGetters = {
        getFilteredTestCases: getters.getFilteredTestCases(state, {
          getAllTestCases: getters.getAllTestCases(state),
        }),
      };

      const results = getters.getSearchResults(state, mockGetters);
      const expected = mockGetters.getFilteredTestCases
        .slice(0, state.pageInfo.perPage)
        .map((testCase) => ({
          ...testCase,
          icon: iconForTestStatus(testCase.status),
          formattedTime: formattedTime(testCase.execution_time),
        }));

      expect(results).toEqual(expected);
    });
  });

  describe('getSearchResultsCount', () => {
    it('should return the total number of filtered test cases', () => {
      setupState({ ...defaultState, searchScope: SEARCH_SCOPE_ALL, searchTerm: '' });
      const mockGetters = {
        getFilteredTestCases: getters.getFilteredTestCases(state, {
          getAllTestCases: getters.getAllTestCases(state),
        }),
      };

      expect(getters.getSearchResultsCount(state, mockGetters)).toBe(
        mockGetters.getFilteredTestCases.length,
      );
    });
  });
});
