import PersistentUserCallout from '~/persistent_user_callout';

function initPrivacyPolicyUpdateCallout() {
  const callout = document.querySelector('.js-privacy-policy-update');
  PersistentUserCallout.factory(callout);
}

export default initPrivacyPolicyUpdateCallout;
