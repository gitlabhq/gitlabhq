export default ({
  fullReportEndpoint = '',
  summaryEndpoint = '',
  useBuildSummaryReport = false,
}) => ({
  summaryEndpoint,
  fullReportEndpoint,
  testReports: {},
  selectedSuiteIndex: null,
  hasFullReport: false,
  isLoading: false,
  useBuildSummaryReport,
});
