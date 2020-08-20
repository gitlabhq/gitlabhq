import $ from 'jquery';
import axios from './lib/utils/axios_utils';
import { deprecatedCreateFlash as Flash, hideFlash } from './flash';
import { parseBoolean } from './lib/utils/common_utils';
import { __ } from './locale';

export default () => {
  $('body').on('click', '.js-usage-consent-action', e => {
    e.preventDefault();
    e.stopImmediatePropagation(); // overwrite rails listener

    const { url, checkEnabled, pingEnabled } = e.target.dataset;
    const data = {
      application_setting: {
        version_check_enabled: parseBoolean(checkEnabled),
        usage_ping_enabled: parseBoolean(pingEnabled),
      },
    };

    const hideConsentMessage = () => hideFlash(document.querySelector('.ping-consent-message'));

    axios
      .put(url, data)
      .then(() => {
        hideConsentMessage();
      })
      .catch(() => {
        hideConsentMessage();
        Flash(__('Something went wrong. Try again later.'));
      });
  });
};
