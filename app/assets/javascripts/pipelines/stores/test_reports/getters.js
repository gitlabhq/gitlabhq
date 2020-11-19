import { addIconStatus, formattedTime } from './utils';

export const getTestSuites = state => {
  const { test_suites: testSuites = [] } = state.testReports;

  return testSuites.map(suite => ({
    ...suite,
    formattedTime: formattedTime(suite.total_time),
  }));
};

export const getSelectedSuite = state =>
  state.testReports?.test_suites?.[state.selectedSuiteIndex] || {};

export const getSuiteTests = state => {
  const { test_cases: testCases = [] } = getSelectedSuite(state);
  const { page, perPage } = state.pageInfo;
  const start = (page - 1) * perPage;

  return testCases.map(addIconStatus).slice(start, start + perPage);
};

export const getSuiteTestCount = state => getSelectedSuite(state)?.test_cases?.length || 0;
