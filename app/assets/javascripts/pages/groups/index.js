import initDismissableCallout from '~/dismissable_callout';
import initGkeDropdowns from '~/projects/gke_cluster_dropdowns';

document.addEventListener('DOMContentLoaded', () => {
  const { page } = document.body.dataset;
  const newClusterViews = [
    'groups:clusters:new',
    'groups:clusters:create_gcp',
    'groups:clusters:create_user',
  ];

  if (newClusterViews.indexOf(page) > -1) {
    initDismissableCallout('.gcp-signup-offer');
    initGkeDropdowns();
  }
});
