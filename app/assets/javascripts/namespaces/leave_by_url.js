import { deprecatedCreateFlash as Flash } from '~/flash';
import { getParameterByName } from '~/lib/utils/common_utils';
import { initRails } from '~/lib/utils/rails_ujs';
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
    Flash(
      sprintf(__('You do not have permission to leave this %{namespaceType}.'), { namespaceType }),
    );
  }
}
