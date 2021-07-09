import createFlash from '~/flash';
import { initRails } from '~/lib/utils/rails_ujs';
import { getParameterByName } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';

const PARAMETER_NAME = 'leave';
const LEAVE_LINK_SELECTOR = '.js-leave-link';

export default function leaveByUrl(namespaceType) {
  if (!namespaceType) throw new Error('namespaceType not provided');

  const param = getParameterByName(PARAMETER_NAME);
  if (!param) return;

  initRails();

  const leaveLink = document.querySelector(LEAVE_LINK_SELECTOR);
  if (leaveLink) {
    leaveLink.click();
  } else {
    createFlash({
      message: sprintf(__('You do not have permission to leave this %{namespaceType}.'), {
        namespaceType,
      }),
    });
  }
}
