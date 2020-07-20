import { addIconStatus, formattedTime, sortTestCases } from './utils';

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
  return testCases.sort(sortTestCases).map(addIconStatus);
};
