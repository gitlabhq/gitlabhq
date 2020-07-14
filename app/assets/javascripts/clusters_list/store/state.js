export default (initialState = {}) => ({
  ancestorHelperPath: initialState.ancestorHelpPath,
  endpoint: initialState.endpoint,
  hasAncestorClusters: false,
  clusters: [],
  clustersPerPage: 0,
  loadingClusters: true,
  loadingNodes: true,
  page: 1,
  providers: {
    aws: { path: initialState.imgTagsAwsPath, text: initialState.imgTagsAwsText },
    default: { path: initialState.imgTagsDefaultPath, text: initialState.imgTagsDefaultText },
    gcp: { path: initialState.imgTagsGcpPath, text: initialState.imgTagsGcpText },
  },
  totalCulsters: 0,
});
