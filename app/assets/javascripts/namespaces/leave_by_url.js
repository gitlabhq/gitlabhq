import { createAlert } from '~/alert';
import { initRails } from '~/lib/utils/rails_ujs';
import { getParameterByName } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';

const PARAMETER_NAME = 'leave';
const PROJECT_LEAVE_LINK_SELECTOR = '.js-leave-link';
const GROUP_LEAVE_LINK_SELECTOR = '#group-more-action-dropdown .js-leave-link';

export const NAMESPACE_TYPES = {
  GROUP: 'group',
  PROJECT: 'project',
};

export default function leaveByUrl(namespaceType) {
  if (!namespaceType) throw new Error('namespaceType not provided');

  const param = getParameterByName(PARAMETER_NAME);
  if (!param) return;

  initRails();

  const LEAVE_LINK_SELECTOR =
    namespaceType === NAMESPACE_TYPES.GROUP
      ? GROUP_LEAVE_LINK_SELECTOR
      : PROJECT_LEAVE_LINK_SELECTOR;

  const leaveLink = document.querySelector(LEAVE_LINK_SELECTOR);
  if (leaveLink) {
    leaveLink.click();
  } else {
    createAlert({
      message: sprintf(__('You do not have permission to leave this %{namespaceType}.'), {
        namespaceType,
      }),
    });
  }
}
