import PersistentUserCallout from '~/persistent_user_callout';

document.addEventListener('DOMContentLoaded', () => {
  const callout = document.querySelector('.js-admin-integrations-moved');
  PersistentUserCallout.factory(callout);
});
