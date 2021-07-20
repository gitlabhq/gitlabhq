import $ from 'jquery';
import createFlash, { hideFlash } from './flash';
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
      hideFlash(document.querySelector('.service-ping-consent-message'));

    axios
      .put(url, data)
      .then(() => {
        hideConsentMessage();
      })
      .catch(() => {
        hideConsentMessage();
        createFlash({
          message: __('Something went wrong. Try again later.'),
        });
      });
  });
};
