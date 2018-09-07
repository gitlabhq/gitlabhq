import $ from 'jquery';
import axios from './lib/utils/axios_utils';
import Flash, { hideFlash } from './flash';
import { convertPermissionToBoolean } from './lib/utils/common_utils';

export default () => {
  $('body').on('click', '.js-usage-consent-action', (e) => {
    e.preventDefault();
    e.stopImmediatePropagation(); // overwrite rails listener

    const { url, checkEnabled, pingEnabled } = e.target.dataset;
    const data = {
      application_setting: {
        version_check_enabled: convertPermissionToBoolean(checkEnabled),
        usage_ping_enabled: convertPermissionToBoolean(pingEnabled),
      },
    };

    const hideConsentMessage = () => hideFlash(document.querySelector('.ping-consent-message'));

    axios.put(url, data)
      .then(() => {
        hideConsentMessage();
      })
      .catch(() => {
        hideConsentMessage();
        Flash('Something went wrong. Try again later.');
      });
  });
};
