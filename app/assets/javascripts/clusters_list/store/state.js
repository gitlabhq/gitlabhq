export default (initialState = {}) => ({
  endpoint: initialState.endpoint,
  hasAncestorClusters: false,
  loading: true,
  clusters: [],
  clustersPerPage: 0,
  page: 1,
  providers: {
    aws: { path: initialState.imgTagsAwsPath, text: initialState.imgTagsAwsText },
    default: { path: initialState.imgTagsDefaultPath, text: initialState.imgTagsDefaultText },
    gcp: { path: initialState.imgTagsGcpPath, text: initialState.imgTagsGcpText },
  },
  totalCulsters: 0,
});
