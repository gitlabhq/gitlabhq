import initSetHelperText, {
  setHelperText,
  checkOptionalMetrics,
} from '~/pages/admin/application_settings/metrics_and_profiling/usage_statistics';

describe('Optional Metrics Tests for EE', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <div id="service_ping_features_helper_text"></div>
      <label id="service_ping_features_label" class=""></label>
      <input type="checkbox" id="application_setting_usage_ping_features_enabled" />
      <input type="checkbox" id="application_setting_usage_ping_enabled" />
      <input type="checkbox" id="application_setting_include_optional_metrics_in_service_ping" />
    `;
  });

  describe('setHelperText Functionality', () => {
    it('should enable helper text when optional metrics are enabled', () => {
      const optionalMetricsServicePingCheckbox = document.getElementById(
        'application_setting_include_optional_metrics_in_service_ping',
      );
      optionalMetricsServicePingCheckbox.checked = true;
      setHelperText(optionalMetricsServicePingCheckbox);

      const helperText = document.getElementById('service_ping_features_helper_text').textContent;
      expect(helperText).toBe(
        'You can enable Registration Features because optional data in Service Ping is enabled.',
      );
    });

    it('should disable helper text when optional metrics are disabled', () => {
      const optionalMetricsServicePingCheckbox = document.getElementById(
        'application_setting_include_optional_metrics_in_service_ping',
      );
      optionalMetricsServicePingCheckbox.checked = false;
      setHelperText(optionalMetricsServicePingCheckbox);

      const helperText = document.getElementById('service_ping_features_helper_text').textContent;
      expect(helperText).toBe(
        'To enable Registration Features, first enable optional data in Service Ping.',
      );
    });
  });

  describe('checkOptionalMetrics Functionality', () => {
    it('should disable optional metrics when service ping is disabled', () => {
      const servicePingCheckbox = document.getElementById('application_setting_usage_ping_enabled');
      servicePingCheckbox.checked = false;
      checkOptionalMetrics(servicePingCheckbox);

      const optionalMetricsCheckbox = document.getElementById(
        'application_setting_include_optional_metrics_in_service_ping',
      );
      expect(optionalMetricsCheckbox.disabled).toBe(true);
      expect(optionalMetricsCheckbox.checked).toBe(false);
    });
  });

  describe('Features checkbox state', () => {
    it('should enable/disable features checkbox when optional metrics checkbox is enabled or disabled', () => {
      initSetHelperText();

      const optionalMetricsServicePingCheckbox = document.getElementById(
        'application_setting_include_optional_metrics_in_service_ping',
      );
      optionalMetricsServicePingCheckbox.checked = true;
      optionalMetricsServicePingCheckbox.dispatchEvent(new Event('change'));

      const servicePingFeaturesCheckbox = document.getElementById(
        'application_setting_usage_ping_features_enabled',
      );

      expect(servicePingFeaturesCheckbox.disabled).toBe(false);

      optionalMetricsServicePingCheckbox.checked = false;
      optionalMetricsServicePingCheckbox.dispatchEvent(new Event('change'));

      expect(servicePingFeaturesCheckbox.disabled).toBe(true);
    });
  });
});

describe('Without Optional Metrics Checkbox for CE', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <div id="service_ping_features_helper_text"></div>
      <label id="service_ping_features_label" class=""></label>
      <input type="checkbox" id="application_setting_usage_ping_features_enabled" />
      <input type="checkbox" id="application_setting_usage_ping_enabled" />
    `;
  });

  describe('initSetHelperText Functionality Without Optional Metrics Checkbox for CE', () => {
    it('should set helper text for service ping when optional metrics checkbox is missing', () => {
      initSetHelperText();

      const servicePingCheckbox = document.getElementById('application_setting_usage_ping_enabled');
      servicePingCheckbox.checked = true;
      servicePingCheckbox.dispatchEvent(new Event('change'));

      let helperText = document.getElementById('service_ping_features_helper_text').textContent;
      expect(helperText).toBe(
        'You can enable Registration Features because Service Ping is enabled.',
      );

      servicePingCheckbox.checked = false;
      servicePingCheckbox.dispatchEvent(new Event('change'));

      helperText = document.getElementById('service_ping_features_helper_text').textContent;
      expect(helperText).toBe('To enable Registration Features, first enable Service Ping.');
    });
    it('should enable/disable features checkbox when enable service ping checkbox is enabled or disabled', () => {
      initSetHelperText();

      const servicePingCheckbox = document.getElementById('application_setting_usage_ping_enabled');
      servicePingCheckbox.checked = true;
      servicePingCheckbox.dispatchEvent(new Event('change'));

      const servicePingFeaturesCheckbox = document.getElementById(
        'application_setting_usage_ping_features_enabled',
      );

      expect(servicePingFeaturesCheckbox.disabled).toBe(false);

      servicePingCheckbox.checked = false;
      servicePingCheckbox.dispatchEvent(new Event('change'));

      expect(servicePingFeaturesCheckbox.disabled).toBe(true);
    });
  });
});
