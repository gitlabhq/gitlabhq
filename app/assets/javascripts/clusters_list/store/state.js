import { parseBoolean } from '~/lib/utils/common_utils';

export default (initialState = {}) => ({
  ancestorHelperPath: initialState.ancestorHelpPath,
  endpoint: initialState.endpoint,
  hasAncestorClusters: false,
  clusters: [],
  clustersPerPage: 20,
  loadingClusters: true,
  loadingNodes: true,
  page: 1,
  providers: {
    aws: { path: initialState.imgTagsAwsPath, text: initialState.imgTagsAwsText },
    default: { path: initialState.imgTagsDefaultPath, text: initialState.imgTagsDefaultText },
    gcp: { path: initialState.imgTagsGcpPath, text: initialState.imgTagsGcpText },
  },
  totalClusters: 0,
  canAddCluster: parseBoolean(initialState.canAddCluster),
});
