export default ({ blobPath = '', summaryEndpoint = '', suiteEndpoint = '' }) => ({
  blobPath,
  summaryEndpoint,
  suiteEndpoint,
  testReports: {},
  selectedSuiteIndex: null,
  isLoading: false,
  errorMessage: null,
  pageInfo: {
    page: 1,
    perPage: 20,
  },
});
