import PersistentUserCallout from '~/persistent_user_callout';
import initGkeDropdowns from '~/projects/gke_cluster_dropdowns';

function initGcpSignupCallout() {
  const callout = document.querySelector('.gcp-signup-offer');
  PersistentUserCallout.factory(callout);
}

document.addEventListener('DOMContentLoaded', () => {
  const { page } = document.body.dataset;
  const newClusterViews = [
    'admin:clusters:new',
    'admin:clusters:create_gcp',
    'admin:clusters:create_user',
  ];

  if (newClusterViews.indexOf(page) > -1) {
    initGcpSignupCallout();
    initGkeDropdowns();
  }
});
