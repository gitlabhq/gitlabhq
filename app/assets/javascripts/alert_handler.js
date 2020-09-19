// This allows us to dismiss alerts that we've migrated from bootstrap
// Note: This ONLY works on alerts that are created on page load
// You can follow this effort in the following epic
// https://gitlab.com/groups/gitlab-org/-/epics/4070

export default function initAlertHandler() {
  const ALERT_SELECTOR = '.gl-alert';
  const CLOSE_SELECTOR = '.gl-alert-dismiss';

  const dismissAlert = ({ target }) => target.closest(ALERT_SELECTOR).remove();
  const closeButtons = document.querySelectorAll(`${ALERT_SELECTOR} ${CLOSE_SELECTOR}`);
  closeButtons.forEach(alert => alert.addEventListener('click', dismissAlert));
}
