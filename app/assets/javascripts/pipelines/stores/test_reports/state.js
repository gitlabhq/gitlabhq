export default ({ fullReportEndpoint = '', summaryEndpoint = '' }) => ({
  summaryEndpoint,
  fullReportEndpoint,
  testReports: {},
  selectedSuite: {},
  summary: {},
  isLoading: false,
});
