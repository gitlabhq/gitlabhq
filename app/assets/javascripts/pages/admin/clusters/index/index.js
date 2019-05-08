import PersistentUserCallout from '~/persistent_user_callout';

document.addEventListener('DOMContentLoaded', () => {
  const callout = document.querySelector('.gcp-signup-offer');
  PersistentUserCallout.factory(callout);
});
