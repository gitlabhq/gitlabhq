import PersistentUserCallout from '~/persistent_user_callout';

document.addEventListener('DOMContentLoaded', () => {
  const callout = document.querySelector('.js-webhooks-moved-alert');
  PersistentUserCallout.factory(callout);
});
