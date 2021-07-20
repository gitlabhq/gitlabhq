import initSetHelperText, {
  HELPER_TEXT_SERVICE_PING_DISABLED,
  HELPER_TEXT_SERVICE_PING_ENABLED,
} from '~/pages/admin/application_settings/metrics_and_profiling/usage_statistics';

describe('UsageStatistics', () => {
  const FIXTURE = 'application_settings/usage.html';
  let usagePingCheckBox;
  let usagePingFeaturesCheckBox;
  let usagePingFeaturesLabel;
  let usagePingFeaturesHelperText;

  beforeEach(() => {
    loadFixtures(FIXTURE);
    initSetHelperText();
    usagePingCheckBox = document.getElementById('application_setting_usage_ping_enabled');
    usagePingFeaturesCheckBox = document.getElementById(
      'application_setting_usage_ping_features_enabled',
    );
    usagePingFeaturesLabel = document.getElementById('service_ping_features_label');
    usagePingFeaturesHelperText = document.getElementById('service_ping_features_helper_text');
  });

  const expectEnabledUsagePingFeaturesCheckBox = () => {
    expect(usagePingFeaturesCheckBox.classList.contains('gl-cursor-not-allowed')).toBe(false);
    expect(usagePingFeaturesHelperText.textContent).toEqual(HELPER_TEXT_SERVICE_PING_ENABLED);
  };

  const expectDisabledUsagePingFeaturesCheckBox = () => {
    expect(usagePingFeaturesLabel.classList.contains('gl-cursor-not-allowed')).toBe(true);
    expect(usagePingFeaturesHelperText.textContent).toEqual(HELPER_TEXT_SERVICE_PING_DISABLED);
  };

  describe('Registration Features checkbox', () => {
    it('is disabled when Usage Ping checkbox is unchecked', () => {
      expect(usagePingCheckBox.checked).toBe(false);
      expectDisabledUsagePingFeaturesCheckBox();
    });

    it('is enabled when Usage Ping checkbox is checked', () => {
      usagePingCheckBox.click();
      expect(usagePingCheckBox.checked).toBe(true);
      expectEnabledUsagePingFeaturesCheckBox();
    });

    it('is switched to disabled when Usage Ping checkbox is unchecked ', () => {
      usagePingCheckBox.click();
      usagePingFeaturesCheckBox.click();
      expectEnabledUsagePingFeaturesCheckBox();

      usagePingCheckBox.click();
      expect(usagePingCheckBox.checked).toBe(false);
      expect(usagePingFeaturesCheckBox.checked).toBe(false);
      expectDisabledUsagePingFeaturesCheckBox();
    });
  });
});
