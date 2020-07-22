export default ({
  fullReportEndpoint = '',
  summaryEndpoint = '',
  suiteEndpoint = '',
  useBuildSummaryReport = false,
}) => ({
  summaryEndpoint,
  suiteEndpoint,
  fullReportEndpoint,
  testReports: {},
  selectedSuiteIndex: null,
  hasFullReport: false,
  isLoading: false,
  useBuildSummaryReport,
});
