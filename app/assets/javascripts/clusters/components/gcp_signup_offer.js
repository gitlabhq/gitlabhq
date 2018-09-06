import PersistentUserCallout from '../../persistent_user_callout';

export default function gcpSignupOffer() {
  const alertEl = document.querySelector('.gcp-signup-offer');
  if (!alertEl) return;

  new PersistentUserCallout(alertEl).init();
}
