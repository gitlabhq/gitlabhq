import $ from 'jquery';
import { createAlert } from '~/alert';
import axios from './lib/utils/axios_utils';
import { parseBoolean } from './lib/utils/common_utils';
import { __ } from './locale';

export default () => {
  $('body').on('click', '.js-service-ping-consent-action', (e) => {
    e.preventDefault();
    e.stopImmediatePropagation(); // overwrite rails listener

    const { url, checkEnabled, servicePingEnabled } = e.target.dataset;
    const data = {
      application_setting: {
        version_check_enabled: parseBoolean(checkEnabled),
        service_ping_enabled: parseBoolean(servicePingEnabled),
      },
    };

    const hideConsentMessage = () =>
      document.querySelector('.service-ping-consent-message .js-close')?.click();

    axios
      .put(url, data)
      .then(() => {
        hideConsentMessage();
      })
      .catch(() => {
        hideConsentMessage();
        createAlert({
          message: __('Something went wrong. Try again later.'),
        });
      });
  });
};
