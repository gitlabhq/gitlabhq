export default ({ blobPath = '', summaryEndpoint = '', suiteEndpoint = '' }) => ({
  blobPath,
  summaryEndpoint,
  suiteEndpoint,
  testReports: {},
  selectedSuiteIndex: null,
  isLoading: false,
  pageInfo: {
    page: 1,
    perPage: 20,
  },
});
