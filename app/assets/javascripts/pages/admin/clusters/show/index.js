import ClustersBundle from '~/clusters/clusters_bundle';
import initClusterHealth from '~/pages/projects/clusters/show/cluster_health';
import initIntegrationForm from '~/clusters/forms/show';

document.addEventListener('DOMContentLoaded', () => {
  new ClustersBundle(); // eslint-disable-line no-new
  initClusterHealth();
  initIntegrationForm();
});
