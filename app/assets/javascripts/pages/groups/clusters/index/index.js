import PersistentUserCallout from '~/persistent_user_callout';
import initClustersListApp from '~/clusters_list';

document.addEventListener('DOMContentLoaded', () => {
  const callout = document.querySelector('.gcp-signup-offer');
  PersistentUserCallout.factory(callout);
  initClustersListApp();
});
