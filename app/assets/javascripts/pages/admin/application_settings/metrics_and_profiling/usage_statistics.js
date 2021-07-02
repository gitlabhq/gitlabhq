import { __ } from '~/locale';

export const HELPER_TEXT_USAGE_PING_DISABLED = __(
  'To enable Registration Features, make sure "Enable service ping" is checked.',
);

export const HELPER_TEXT_USAGE_PING_ENABLED = __(
  'You can enable Registration Features because Service Ping is enabled. To continue using Registration Features in the future, you will also need to register with GitLab via a new cloud licensing service.',
);

function setHelperText(usagePingCheckbox) {
  const helperTextId = document.getElementById('usage_ping_features_helper_text');

  const usagePingFeaturesLabel = document.getElementById('usage_ping_features_label');

  const usagePingFeaturesCheckbox = document.getElementById(
    'application_setting_usage_ping_features_enabled',
  );

  helperTextId.textContent = usagePingCheckbox.checked
    ? HELPER_TEXT_USAGE_PING_ENABLED
    : HELPER_TEXT_USAGE_PING_DISABLED;

  usagePingFeaturesLabel.classList.toggle('gl-cursor-not-allowed', !usagePingCheckbox.checked);

  usagePingFeaturesCheckbox.disabled = !usagePingCheckbox.checked;

  if (!usagePingCheckbox.checked) {
    usagePingFeaturesCheckbox.disabled = true;
    usagePingFeaturesCheckbox.checked = false;
  }
}

export default function initSetHelperText() {
  const usagePingCheckbox = document.getElementById('application_setting_usage_ping_enabled');

  setHelperText(usagePingCheckbox);
  usagePingCheckbox.addEventListener('change', () => {
    setHelperText(usagePingCheckbox);
  });
}
