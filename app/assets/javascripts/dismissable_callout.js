import PersistentUserCallout from '../../persistent_user_callout';

export default function initDismissableCallout(alertSelector) {
  const alertEl = document.querySelector(alertSelector);
  if (!alertEl) {
    return;
  }

  new PersistentUserCallout(alertEl);
}
