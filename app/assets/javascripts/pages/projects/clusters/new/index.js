document.addEventListener('DOMContentLoaded', () => {
  if (gon.features.createEksClusters) {
    import(/* webpackChunkName: 'eks_cluster' */ '~/create_cluster/eks_cluster')
      .then(({ default: initCreateEKSCluster }) => {
        const el = document.querySelector('.js-create-eks-cluster-form-container');

        if (el) {
          initCreateEKSCluster(el);
        }
      })
      .catch(() => {});
  }
});
