import { addIconStatus, formatFilePath, formattedTime } from './utils';
import { ARTIFACTS_EXPIRED_ERROR_MESSAGE } from './constants';

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
