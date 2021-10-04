import { __ } from '~/locale';

export const HELPER_TEXT_SERVICE_PING_DISABLED = __(
  'To enable Registration Features, first enable Service Ping.',
);

export const HELPER_TEXT_SERVICE_PING_ENABLED = __(
  'You can enable Registration Features because Service Ping is enabled. To continue using Registration Features in the future, you will also need to register with GitLab via a new cloud licensing service.',
);

function setHelperText(servicePingCheckbox) {
  const helperTextId = document.getElementById('service_ping_features_helper_text');

  const servicePingFeaturesLabel = document.getElementById('service_ping_features_label');

  const servicePingFeaturesCheckbox = document.getElementById(
    'application_setting_usage_ping_features_enabled',
  );

  helperTextId.textContent = servicePingCheckbox.checked
    ? HELPER_TEXT_SERVICE_PING_ENABLED
    : HELPER_TEXT_SERVICE_PING_DISABLED;

  servicePingFeaturesLabel.classList.toggle('gl-cursor-not-allowed', !servicePingCheckbox.checked);

  servicePingFeaturesCheckbox.disabled = !servicePingCheckbox.checked;

  if (!servicePingCheckbox.checked) {
    servicePingFeaturesCheckbox.disabled = true;
    servicePingFeaturesCheckbox.checked = false;
  }
}

export default function initSetHelperText() {
  const servicePingCheckbox = document.getElementById('application_setting_usage_ping_enabled');

  setHelperText(servicePingCheckbox);
  servicePingCheckbox.addEventListener('change', () => {
    setHelperText(servicePingCheckbox);
  });
}
