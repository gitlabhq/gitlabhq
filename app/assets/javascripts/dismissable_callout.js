import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import Flash from '~/flash';

export default function initDismissableCallout(alertSelector) {
  const alertEl = document.querySelector(alertSelector);
  if (!alertEl) {
    return;
  }

  const closeButtonEl = alertEl.getElementsByClassName('close')[0];
  const { dismissEndpoint, featureId } = closeButtonEl.dataset;

  closeButtonEl.addEventListener('click', () => {
    axios
      .post(dismissEndpoint, {
        feature_name: featureId,
      })
      .then(() => {
        $(alertEl).alert('close');
      })
      .catch(() => {
        Flash(__('An error occurred while dismissing the alert. Refresh the page and try again.'));
      });
  });
}
