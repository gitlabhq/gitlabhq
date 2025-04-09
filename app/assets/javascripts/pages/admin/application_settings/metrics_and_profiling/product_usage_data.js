import { ELEMENT_IDS } from './constants';

export default function initProductUsageData() {
  const productUsageCheckbox = document.getElementById(ELEMENT_IDS.PRODUCT_USAGE_DATA);
  const snowplowCheckbox = document.getElementById(ELEMENT_IDS.SNOWPLOW_ENABLED);
  const snowplowSettings = document.getElementById('js-snowplow-settings');

  const toggleSnowplowSettings = () => {
    if (!snowplowCheckbox || !snowplowSettings) return;

    if (snowplowCheckbox.checked) {
      snowplowSettings.style.display = 'block';
    } else {
      snowplowSettings.style.display = 'none';
    }
  };

  toggleSnowplowSettings();

  productUsageCheckbox?.addEventListener('change', () => {
    if (productUsageCheckbox.checked) {
      snowplowCheckbox.checked = false;
      toggleSnowplowSettings();
    }
  });

  snowplowCheckbox?.addEventListener('change', () => {
    if (snowplowCheckbox.checked) {
      productUsageCheckbox.checked = false;
    }
    toggleSnowplowSettings();
  });
}
