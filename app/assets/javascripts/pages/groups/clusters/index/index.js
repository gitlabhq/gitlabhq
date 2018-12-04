import PersistentUserCallout from '~/persistent_user_callout';

document.addEventListener('DOMContentLoaded', () => {
  const callout = document.querySelector('.gcp-signup-offer');

  if (callout) new PersistentUserCallout(callout); // eslint-disable-line no-new
});
