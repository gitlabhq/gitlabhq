import { mount2faRegistration } from '~/authentication/mount_2fa';
import { initWebAuthnRegistration } from '~/authentication/webauthn/registration';
import { initRecoveryCodes, initManageTwoFactorForm } from '~/authentication/two_factor_auth';
import { parseBoolean } from '~/lib/utils/common_utils';

const twoFactorNode = document.querySelector('.js-two-factor-auth');
const skippable = twoFactorNode ? parseBoolean(twoFactorNode.dataset.twoFactorSkippable) : false;

if (skippable) {
  const button = `<br/><a class="btn gl-button btn-sm btn-confirm gl-mt-3" data-qa-selector="configure_it_later_button" data-method="patch" href="${twoFactorNode.dataset.two_factor_skip_url}">Configure it later</a>`;
  const flashAlert = document.querySelector('.flash-alert');
  if (flashAlert) {
    // eslint-disable-next-line no-unsanitized/method
    flashAlert.insertAdjacentHTML('beforeend', button);
  }
}

mount2faRegistration();
initWebAuthnRegistration();

initRecoveryCodes();

initManageTwoFactorForm();
