import { SEARCH_SCOPE_SUITE } from './constants';

export default ({ blobPath = '', summaryEndpoint = '', suiteEndpoint = '' }) => ({
  blobPath,
  summaryEndpoint,
  suiteEndpoint,
  testReports: {},
  selectedSuiteIndex: null,
  isLoading: false,
  errorMessage: null,
  searchTerm: '',
  searchScope: SEARCH_SCOPE_SUITE,
  hasFetchedAllSuites: false,
  isLoadingAllSuites: false,
  pageInfo: {
    page: 1,
    perPage: 20,
  },
});
