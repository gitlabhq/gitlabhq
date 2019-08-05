import PersistentUserCallout from '~/persistent_user_callout';

function initPrivacyPolicyUpdateCallout() {
  const callout = document.querySelector('.privacy-policy-update-64341');
  PersistentUserCallout.factory(callout);
}

export default initPrivacyPolicyUpdateCallout;
