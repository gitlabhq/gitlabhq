import {
  ELEMENT_IDS,
  HELPER_TEXT_SERVICE_PING_DISABLED,
  HELPER_TEXT_SERVICE_PING_ENABLED,
  HELPER_TEXT_OPTIONAL_METRICS_DISABLED,
  HELPER_TEXT_OPTIONAL_METRICS_ENABLED,
} from './constants';

export function setHelperText(checkbox) {
  const helperTextId = document.getElementById(ELEMENT_IDS.HELPER_TEXT);
  const servicePingFeaturesLabel = document.getElementById(ELEMENT_IDS.SERVICE_PING_FEATURES_LABEL);
  const servicePingFeaturesCheckbox = document.getElementById(
    ELEMENT_IDS.USAGE_PING_FEATURES_ENABLED,
  );
  const optionalMetricsServicePingCheckbox = document.getElementById(
    ELEMENT_IDS.OPTIONAL_METRICS_IN_SERVICE_PING,
  );

  if (optionalMetricsServicePingCheckbox) {
    helperTextId.textContent = checkbox.checked
      ? HELPER_TEXT_OPTIONAL_METRICS_ENABLED
      : HELPER_TEXT_OPTIONAL_METRICS_DISABLED;
  } else {
    helperTextId.textContent = checkbox.checked
      ? HELPER_TEXT_SERVICE_PING_ENABLED
      : HELPER_TEXT_SERVICE_PING_DISABLED;
  }

  servicePingFeaturesLabel.classList.toggle('gl-cursor-not-allowed', !checkbox.checked);
  servicePingFeaturesCheckbox.disabled = !checkbox.checked;

  if (!checkbox.checked) {
    servicePingFeaturesCheckbox.disabled = true;
    servicePingFeaturesCheckbox.checked = false;
  }
}

export function checkOptionalMetrics(servicePingCheckbox) {
  const optionalMetricsServicePingCheckbox = document.getElementById(
    ELEMENT_IDS.OPTIONAL_METRICS_IN_SERVICE_PING,
  );
  const servicePingFeaturesCheckbox = document.getElementById(
    ELEMENT_IDS.USAGE_PING_FEATURES_ENABLED,
  );
  const usagePingGenerationCheckbox = document.getElementById(
    ELEMENT_IDS.USAGE_PING_GENERATION_ENABLED,
  );

  const isServicePingEnabled = servicePingCheckbox.checked;
  const isGenerationEnabled = usagePingGenerationCheckbox
    ? usagePingGenerationCheckbox.checked
    : true;
  const shouldEnableOptionalMetrics = isServicePingEnabled || isGenerationEnabled;

  if (!shouldEnableOptionalMetrics) {
    optionalMetricsServicePingCheckbox.disabled = true;
    optionalMetricsServicePingCheckbox.checked = false;
    if (servicePingFeaturesCheckbox) {
      servicePingFeaturesCheckbox.disabled = true;
      servicePingFeaturesCheckbox.checked = false;
    }
  } else {
    optionalMetricsServicePingCheckbox.disabled = false;
  }
}

/**
 * Controls the state of usage ping generation checkbox based on service ping status.
 * When Service Ping is checked, generation must be checked and disabled
 * When Service Ping is unchecked, generation checkbox becomes enabled.
 * @param {HTMLInputElement} servicePingCheckbox - The service ping checkbox element
 */
export function checkUsagePingGeneration(servicePingCheckbox) {
  const usagePingGenerationCheckbox = document.getElementById(
    ELEMENT_IDS.USAGE_PING_GENERATION_ENABLED,
  );

  if (!usagePingGenerationCheckbox) return;

  if (servicePingCheckbox.checked) {
    usagePingGenerationCheckbox.checked = true;
    usagePingGenerationCheckbox.disabled = true;
  } else {
    usagePingGenerationCheckbox.disabled = false;
  }
}

export function initOptionMetricsState() {
  const servicePingCheckbox = document.getElementById(ELEMENT_IDS.USAGE_PING_ENABLED);
  const optionalMetricsServicePingCheckbox = document.getElementById(
    ELEMENT_IDS.OPTIONAL_METRICS_IN_SERVICE_PING,
  );
  if (servicePingCheckbox && optionalMetricsServicePingCheckbox) {
    checkOptionalMetrics(servicePingCheckbox);
    servicePingCheckbox.addEventListener('change', () => {
      checkOptionalMetrics(servicePingCheckbox);
    });
  }
}

export function initUsagePingGenerationState() {
  const servicePingCheckbox = document.getElementById(ELEMENT_IDS.USAGE_PING_ENABLED);
  const usagePingGenerationCheckbox = document.getElementById(
    ELEMENT_IDS.USAGE_PING_GENERATION_ENABLED,
  );

  if (servicePingCheckbox && usagePingGenerationCheckbox) {
    // Only set initial disabled state without changing checked state
    if (servicePingCheckbox.checked) {
      usagePingGenerationCheckbox.disabled = true;
    } else {
      usagePingGenerationCheckbox.disabled = false;
    }

    servicePingCheckbox.addEventListener('change', () => {
      checkUsagePingGeneration(servicePingCheckbox);
    });

    usagePingGenerationCheckbox.addEventListener('change', () => {
      checkOptionalMetrics(servicePingCheckbox);
    });
  }
}

export default function initSetHelperText() {
  const servicePingCheckbox = document.getElementById(ELEMENT_IDS.USAGE_PING_ENABLED);
  const optionalMetricsServicePingCheckbox = document.getElementById(
    ELEMENT_IDS.OPTIONAL_METRICS_IN_SERVICE_PING,
  );
  const checkbox = optionalMetricsServicePingCheckbox || servicePingCheckbox;

  setHelperText(checkbox);
  checkbox.addEventListener('change', () => {
    setHelperText(checkbox);
  });
}
