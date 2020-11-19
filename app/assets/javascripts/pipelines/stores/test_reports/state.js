export default ({ summaryEndpoint = '', suiteEndpoint = '' }) => ({
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
