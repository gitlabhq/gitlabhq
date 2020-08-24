import PersistentUserCallout from '~/persistent_user_callout';

document.addEventListener('DOMContentLoaded', () => {
  const callout = document.querySelector('.js-service-templates-deprecated');
  PersistentUserCallout.factory(callout);
});
