import ClustersBundle from '~/clusters/clusters_bundle';
import initGkeNamespace from '~/create_cluster/gke_cluster_namespace';

document.addEventListener('DOMContentLoaded', () => {
  new ClustersBundle(); // eslint-disable-line no-new
  initGkeNamespace();
});
