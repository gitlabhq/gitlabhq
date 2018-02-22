import ClustersBundle from '~/clusters/clusters_bundle';
import initClusterHealth from './cluster_health';

document.addEventListener('DOMContentLoaded', () => {
  new ClustersBundle(); // eslint-disable-line no-new
  initClusterHealth();
});
