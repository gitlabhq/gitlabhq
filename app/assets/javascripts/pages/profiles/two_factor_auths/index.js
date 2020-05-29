import { parseBoolean } from '~/lib/utils/common_utils';
import { mount2faRegistration } from '~/authentication/mount_2fa';

document.addEventListener('DOMContentLoaded', () => {
  const twoFactorNode = document.querySelector('.js-two-factor-auth');
  const skippable = parseBoolean(twoFactorNode.dataset.twoFactorSkippable);

  if (skippable) {
    const button = `<a class="btn btn-sm btn-warning float-right" data-qa-selector="configure_it_later_button" data-method="patch" href="${twoFactorNode.dataset.two_factor_skip_url}">Configure it later</a>`;
    const flashAlert = document.querySelector('.flash-alert');
    if (flashAlert) flashAlert.insertAdjacentHTML('beforeend', button);
  }

  mount2faRegistration();
});
