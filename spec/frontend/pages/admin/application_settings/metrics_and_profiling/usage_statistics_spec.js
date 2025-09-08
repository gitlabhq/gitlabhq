import initSetHelperText, {
  setHelperText,
  checkOptionalMetrics,
  checkUsagePingGeneration,
  initUsagePingGenerationState,
} from '~/pages/admin/application_settings/metrics_and_profiling/usage_statistics';

describe('Optional Metrics Tests for EE', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <div id="service_ping_features_helper_text"></div>
      <label id="service_ping_features_label" class=""></label>
      <input type="checkbox" id="application_setting_usage_ping_features_enabled" />
      <input type="checkbox" id="application_setting_usage_ping_enabled" />
      <input type="checkbox" id="application_setting_usage_ping_generation_enabled" />
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

    it('should enable optional metrics when generation is enabled but service ping is disabled', () => {
      const servicePingCheckbox = document.getElementById('application_setting_usage_ping_enabled');
      const generationCheckbox = document.getElementById(
        'application_setting_usage_ping_generation_enabled',
      );
      const optionalMetricsCheckbox = document.getElementById(
        'application_setting_include_optional_metrics_in_service_ping',
      );

      servicePingCheckbox.checked = false;
      generationCheckbox.checked = true;
      checkOptionalMetrics(servicePingCheckbox);

      expect(optionalMetricsCheckbox.disabled).toBe(false);
    });

    it('should enable optional metrics when service ping is enabled', () => {
      const servicePingCheckbox = document.getElementById('application_setting_usage_ping_enabled');
      const generationCheckbox = document.getElementById(
        'application_setting_usage_ping_generation_enabled',
      );
      const optionalMetricsCheckbox = document.getElementById(
        'application_setting_include_optional_metrics_in_service_ping',
      );

      servicePingCheckbox.checked = true;
      generationCheckbox.checked = false;
      checkOptionalMetrics(servicePingCheckbox);

      expect(optionalMetricsCheckbox.disabled).toBe(false);
    });

    it('should disable optional metrics when both service ping and generation are disabled', () => {
      const servicePingCheckbox = document.getElementById('application_setting_usage_ping_enabled');
      const generationCheckbox = document.getElementById(
        'application_setting_usage_ping_generation_enabled',
      );
      const optionalMetricsCheckbox = document.getElementById(
        'application_setting_include_optional_metrics_in_service_ping',
      );

      servicePingCheckbox.checked = false;
      generationCheckbox.checked = false;
      checkOptionalMetrics(servicePingCheckbox);

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
      <input type="checkbox" id="application_setting_usage_ping_generation_enabled" />
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

describe('Usage Ping Generation Functionality', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <input type="checkbox" id="application_setting_usage_ping_enabled" />
      <input type="checkbox" id="application_setting_usage_ping_generation_enabled" />
    `;
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  describe('checkUsagePingGeneration', () => {
    it('should check and disable generation checkbox when service ping is enabled', () => {
      const servicePingCheckbox = document.getElementById('application_setting_usage_ping_enabled');
      const generationCheckbox = document.getElementById(
        'application_setting_usage_ping_generation_enabled',
      );

      servicePingCheckbox.checked = true;
      checkUsagePingGeneration(servicePingCheckbox);

      expect(generationCheckbox.checked).toBe(true);
      expect(generationCheckbox.disabled).toBe(true);
    });

    it('should enable generation checkbox when service ping is disabled', () => {
      const servicePingCheckbox = document.getElementById('application_setting_usage_ping_enabled');
      const generationCheckbox = document.getElementById(
        'application_setting_usage_ping_generation_enabled',
      );

      generationCheckbox.checked = false;
      servicePingCheckbox.checked = false;
      checkUsagePingGeneration(servicePingCheckbox);

      expect(generationCheckbox.disabled).toBe(false);
      expect(generationCheckbox.checked).toBe(false); // original state
    });

    it('should handle missing generation checkbox gracefully', () => {
      document.body.innerHTML = `
        <input type="checkbox" id="application_setting_usage_ping_enabled" />
      `;

      const servicePingCheckbox = document.getElementById('application_setting_usage_ping_enabled');
      servicePingCheckbox.checked = true;

      expect(() => checkUsagePingGeneration(servicePingCheckbox)).not.toThrow();
    });
  });

  describe('initUsagePingGenerationState', () => {
    it('should initialize generation checkbox state based on service ping checkbox', () => {
      const servicePingCheckbox = document.getElementById('application_setting_usage_ping_enabled');
      const generationCheckbox = document.getElementById(
        'application_setting_usage_ping_generation_enabled',
      );

      servicePingCheckbox.checked = true;
      generationCheckbox.checked = false;
      initUsagePingGenerationState();

      expect(generationCheckbox.checked).toBe(false); // server-side value
      expect(generationCheckbox.disabled).toBe(true);
    });

    it('should respond to service ping checkbox changes', () => {
      const servicePingCheckbox = document.getElementById('application_setting_usage_ping_enabled');
      const generationCheckbox = document.getElementById(
        'application_setting_usage_ping_generation_enabled',
      );

      initUsagePingGenerationState();

      servicePingCheckbox.checked = true;
      servicePingCheckbox.dispatchEvent(new Event('change'));

      expect(generationCheckbox.checked).toBe(true);
      expect(generationCheckbox.disabled).toBe(true);

      servicePingCheckbox.checked = false;
      servicePingCheckbox.dispatchEvent(new Event('change'));

      expect(generationCheckbox.disabled).toBe(false);
    });

    it('should update optional metrics when generation checkbox changes', () => {
      document.body.innerHTML = `
        <input type="checkbox" id="application_setting_usage_ping_enabled" />
        <input type="checkbox" id="application_setting_usage_ping_generation_enabled" checked />
        <input type="checkbox" id="application_setting_include_optional_metrics_in_service_ping" />
        <input type="checkbox" id="application_setting_usage_ping_features_enabled" />
      `;

      const generationCheckbox = document.getElementById(
        'application_setting_usage_ping_generation_enabled',
      );
      const optionalMetricsCheckbox = document.getElementById(
        'application_setting_include_optional_metrics_in_service_ping',
      );

      initUsagePingGenerationState();

      // When generation is unchecked and service ping is disabled, optional metrics should be disabled
      generationCheckbox.checked = false;
      generationCheckbox.dispatchEvent(new Event('change'));

      expect(optionalMetricsCheckbox.disabled).toBe(true);
      expect(optionalMetricsCheckbox.checked).toBe(false);

      // When generation is checked again, optional metrics should be enabled (even with service ping disabled)
      generationCheckbox.checked = true;
      generationCheckbox.dispatchEvent(new Event('change'));

      expect(optionalMetricsCheckbox.disabled).toBe(false);
    });

    it('should handle missing checkboxes gracefully', () => {
      document.body.innerHTML = '';

      expect(() => initUsagePingGenerationState()).not.toThrow();
    });
  });
});
