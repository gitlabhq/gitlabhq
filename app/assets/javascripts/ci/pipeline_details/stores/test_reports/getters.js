import { addIconStatus, filterTestCases, formatFilePath, formattedTime } from './utils';
import { ARTIFACTS_EXPIRED_ERROR_MESSAGE, SEARCH_SCOPE_SUITE } from './constants';

export const getTestSuites = (state) => {
  const { test_suites: testSuites = [] } = state.testReports;

  return testSuites.map((suite) => ({
    ...suite,
    formattedTime: formattedTime(suite.total_time),
  }));
};

export const getSelectedSuite = (state) =>
  state.testReports?.test_suites?.[state.selectedSuiteIndex] || {};

export const getSuiteTests = (state) => {
  const { test_cases: testCases = [] } = getSelectedSuite(state);
  const { page, perPage } = state.pageInfo;
  const start = (page - 1) * perPage;

  return testCases
    .map((testCase) => ({
      ...testCase,
      classname: testCase.classname || '',
      name: testCase.name || '',
      filePath: testCase.file ? `${state.blobPath}/${formatFilePath(testCase.file)}` : null,
    }))
    .map(addIconStatus)
    .slice(start, start + perPage);
};

export const getSuiteTestCount = (state) => getSelectedSuite(state)?.test_cases?.length || 0;

export const getSuiteArtifactsExpired = (state) =>
  state.errorMessage === ARTIFACTS_EXPIRED_ERROR_MESSAGE;

export const getTotalSuiteCount = (state) => state.testReports?.test_suites?.length || 0;

export const isSearching = (state) => state.searchTerm.trim().length > 0;

export const getAllTestCases = (state) => {
  const { test_suites: testSuites = [] } = state.testReports;

  return testSuites.flatMap((suite) =>
    (suite.test_cases || []).map((testCase) => ({
      ...testCase,
      classname: testCase.classname || '',
      name: testCase.name || '',
      suiteName: suite.name,
      filePath: testCase.file ? `${state.blobPath}/${formatFilePath(testCase.file)}` : null,
    })),
  );
};

export const getFilteredTestCases = (state, getters) => {
  const allTestCases = getters?.getAllTestCases ?? getAllTestCases(state);
  const pool =
    state.searchScope === SEARCH_SCOPE_SUITE && state.selectedSuiteIndex !== null
      ? allTestCases.filter(
          (tc) => tc.suiteName === state.testReports?.test_suites?.[state.selectedSuiteIndex]?.name,
        )
      : allTestCases;

  return filterTestCases(pool, state.searchTerm);
};

export const getSearchResults = (state, getters) => {
  const { page, perPage } = state.pageInfo;
  const start = (page - 1) * perPage;

  return getters.getFilteredTestCases.slice(start, start + perPage).map(addIconStatus);
};

export const getSearchResultsCount = (state, getters) => getters.getFilteredTestCases.length;
