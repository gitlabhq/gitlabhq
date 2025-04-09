import initProductUsageData from '~/pages/admin/application_settings/metrics_and_profiling/product_usage_data';
import { ELEMENT_IDS } from '~/pages/admin/application_settings/metrics_and_profiling/constants';

describe('Product Usage Data', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <input type="checkbox" id="${ELEMENT_IDS.PRODUCT_USAGE_DATA}" />
      <input type="checkbox" id="${ELEMENT_IDS.SNOWPLOW_ENABLED}" />
      <div id="js-snowplow-settings" style="display: none;"></div>
    `;
  });

  describe('initProductUsageData Functionality', () => {
    it('should hide snowplow settings when snowplow is not checked', () => {
      initProductUsageData();

      const snowplowSettings = document.getElementById('js-snowplow-settings');
      expect(snowplowSettings.style.display).toBe('none');
    });

    it('should show snowplow settings when snowplow is checked', () => {
      const snowplowCheckbox = document.getElementById(ELEMENT_IDS.SNOWPLOW_ENABLED);
      snowplowCheckbox.checked = true;

      initProductUsageData();

      const snowplowSettings = document.getElementById('js-snowplow-settings');
      expect(snowplowSettings.style.display).toBe('block');
    });

    it('should uncheck snowplow when product usage is checked', () => {
      initProductUsageData();

      const productUsageCheckbox = document.getElementById(ELEMENT_IDS.PRODUCT_USAGE_DATA);
      const snowplowCheckbox = document.getElementById(ELEMENT_IDS.SNOWPLOW_ENABLED);

      snowplowCheckbox.checked = true;
      productUsageCheckbox.checked = true;
      productUsageCheckbox.dispatchEvent(new Event('change'));

      expect(snowplowCheckbox.checked).toBe(false);
    });

    it('should uncheck product usage when snowplow is checked', () => {
      initProductUsageData();

      const productUsageCheckbox = document.getElementById(ELEMENT_IDS.PRODUCT_USAGE_DATA);
      const snowplowCheckbox = document.getElementById(ELEMENT_IDS.SNOWPLOW_ENABLED);

      productUsageCheckbox.checked = true;
      snowplowCheckbox.checked = true;
      snowplowCheckbox.dispatchEvent(new Event('change'));

      expect(productUsageCheckbox.checked).toBe(false);
    });

    it('should toggle snowplow settings visibility when snowplow checkbox changes', () => {
      initProductUsageData();

      const snowplowCheckbox = document.getElementById(ELEMENT_IDS.SNOWPLOW_ENABLED);
      const snowplowSettings = document.getElementById('js-snowplow-settings');

      snowplowCheckbox.checked = true;
      snowplowCheckbox.dispatchEvent(new Event('change'));
      expect(snowplowSettings.style.display).toBe('block');

      snowplowCheckbox.checked = false;
      snowplowCheckbox.dispatchEvent(new Event('change'));
      expect(snowplowSettings.style.display).toBe('none');
    });
  });
});
