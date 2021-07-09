import ClustersBundle from '~/clusters/clusters_bundle';
import initIntegrationForm from '~/clusters/forms/show';
import initClusterHealth from '~/pages/projects/clusters/show/cluster_health';

new ClustersBundle(); // eslint-disable-line no-new
initClusterHealth();
initIntegrationForm();
