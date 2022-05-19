import ClustersBundle from '~/clusters/clusters_bundle';
import initIntegrationForm from '~/clusters/forms/show';
import initGkeNamespace from '~/clusters/gke_cluster_namespace';
import initClusterHealth from './cluster_health';

new ClustersBundle(); // eslint-disable-line no-new
initGkeNamespace();
initClusterHealth();
initIntegrationForm();
