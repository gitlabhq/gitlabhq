import { addIconStatus, formattedTime, sortTestCases } from './utils';

export const getTestSuites = state => {
  const { test_suites: testSuites = [] } = state.testReports;

  return testSuites.map(suite => ({
    ...suite,
    formattedTime: formattedTime(suite.total_time),
  }));
};

export const getSuiteTests = state => {
  const { selectedSuite } = state;

  if (selectedSuite.test_cases) {
    return selectedSuite.test_cases.sort(sortTestCases).map(addIconStatus);
  }

  return [];
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
