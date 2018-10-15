import initDismissableCallout from '~/dismissable_callout';
import initGkeDropdowns from '~/projects/gke_cluster_dropdowns';

document.addEventListener('DOMContentLoaded', () => {
  initDismissableCallout('.gcp-signup-offer');
  initGkeDropdowns();
});
