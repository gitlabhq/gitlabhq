import PersistentUserCallout from '~/persistent_user_callout';
import initGkeDropdowns from '~/projects/gke_cluster_dropdowns';

function initGcpSignupCallout() {
  const callout = document.querySelector('.gcp-signup-offer');
  PersistentUserCallout.factory(callout);
}

document.addEventListener('DOMContentLoaded', () => {
  const { page } = document.body.dataset;
  const newClusterViews = [
    'groups:clusters:new',
    'groups:clusters:create_gcp',
    'groups:clusters:create_user',
  ];

  if (newClusterViews.indexOf(page) > -1) {
    initGcpSignupCallout();
    initGkeDropdowns();
  }
});
