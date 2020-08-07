export default ({ summaryEndpoint = '', suiteEndpoint = '' }) => ({
  summaryEndpoint,
  suiteEndpoint,
  testReports: {},
  selectedSuiteIndex: null,
  isLoading: false,
});
