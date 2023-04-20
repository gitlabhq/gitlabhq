import htmlApplicationSettingsUsage from 'test_fixtures/application_settings/usage.html';
import initSetHelperText, {
  HELPER_TEXT_SERVICE_PING_DISABLED,
  HELPER_TEXT_SERVICE_PING_ENABLED,
} from '~/pages/admin/application_settings/metrics_and_profiling/usage_statistics';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

describe('UsageStatistics', () => {
  let servicePingCheckBox;
  let servicePingFeaturesCheckBox;
  let servicePingFeaturesLabel;
  let servicePingFeaturesHelperText;

  beforeEach(() => {
    setHTMLFixture(htmlApplicationSettingsUsage);
    initSetHelperText();
    servicePingCheckBox = document.getElementById('application_setting_usage_ping_enabled');
    servicePingFeaturesCheckBox = document.getElementById(
      'application_setting_usage_ping_features_enabled',
    );
    servicePingFeaturesLabel = document.getElementById('service_ping_features_label');
    servicePingFeaturesHelperText = document.getElementById('service_ping_features_helper_text');
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  const expectEnabledservicePingFeaturesCheckBox = () => {
    expect(servicePingFeaturesCheckBox.classList.contains('gl-cursor-not-allowed')).toBe(false);
    expect(servicePingFeaturesHelperText.textContent).toEqual(HELPER_TEXT_SERVICE_PING_ENABLED);
  };

  const expectDisabledservicePingFeaturesCheckBox = () => {
    expect(servicePingFeaturesLabel.classList.contains('gl-cursor-not-allowed')).toBe(true);
    expect(servicePingFeaturesHelperText.textContent).toEqual(HELPER_TEXT_SERVICE_PING_DISABLED);
  };

  describe('Registration Features checkbox', () => {
    it('is disabled when Service Ping checkbox is unchecked', () => {
      expect(servicePingCheckBox.checked).toBe(false);
      expectDisabledservicePingFeaturesCheckBox();
    });

    it('is enabled when Servie Ping checkbox is checked', () => {
      servicePingCheckBox.click();
      expect(servicePingCheckBox.checked).toBe(true);
      expectEnabledservicePingFeaturesCheckBox();
    });

    it('is switched to disabled when Service Ping checkbox is unchecked', () => {
      servicePingCheckBox.click();
      servicePingFeaturesCheckBox.click();
      expectEnabledservicePingFeaturesCheckBox();

      servicePingCheckBox.click();
      expect(servicePingCheckBox.checked).toBe(false);
      expect(servicePingFeaturesCheckBox.checked).toBe(false);
      expectDisabledservicePingFeaturesCheckBox();
    });
  });
});
