export default ({ fullReportEndpoint = '', summaryEndpoint = '' }) => ({
  summaryEndpoint,
  fullReportEndpoint,
  testReports: {},
  selectedSuiteIndex: null,
  summary: {},
  isLoading: false,
});
