import initClustersListApp from '~/clusters_list';
import PersistentUserCallout from '~/persistent_user_callout';

const callout = document.querySelector('.gcp-signup-offer');
PersistentUserCallout.factory(callout);
initClustersListApp();
