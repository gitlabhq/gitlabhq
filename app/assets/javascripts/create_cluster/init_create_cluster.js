import initGkeDropdowns from './gke_cluster';
import initGkeNamespace from './gke_cluster_namespace';
import PersistentUserCallout from '~/persistent_user_callout';

const newClusterViews = [':clusters:new', ':clusters:create_gcp', ':clusters:create_user'];

const isProjectLevelCluster = page => page.startsWith('project:clusters');

export default document => {
  const { page } = document.body.dataset;
  const isNewClusterView = newClusterViews.some(view => page.endsWith(view));

  if (!isNewClusterView) {
    return;
  }

  const callout = document.querySelector('.gcp-signup-offer');
  PersistentUserCallout.factory(callout);

  initGkeDropdowns();

  import(/* webpackChunkName: 'eks_cluster' */ '~/create_cluster/eks_cluster')
    .then(({ default: initCreateEKSCluster }) => {
      const el = document.querySelector('.js-create-eks-cluster-form-container');

      if (el) {
        initCreateEKSCluster(el);
      }
    })
    .catch(() => {});

  if (isProjectLevelCluster(page)) {
    initGkeNamespace();
  }
};
