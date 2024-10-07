import { mount2faRegistration } from '~/authentication/mount_2fa';
import { initWebAuthnRegistration } from '~/authentication/webauthn/registration';
import {
  initRecoveryCodes,
  initManageTwoFactorForm,
  initTwoFactorConfirm,
} from '~/authentication/two_factor_auth';
import { parseBoolean } from '~/lib/utils/common_utils';

const twoFactorNode = document.querySelector('.js-two-factor-auth');
const skippable = twoFactorNode ? parseBoolean(twoFactorNode.dataset.twoFactorSkippable) : false;

if (skippable) {
  const button = `<div class="gl-alert-actions">
                    <a class="btn gl-button btn-md btn-confirm gl-alert-action" data-testid="configure-it-later-button" data-method="patch" href="${twoFactorNode.dataset.two_factor_skip_url}">Configure it later</a>
                  </div>`;
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
initTwoFactorConfirm();
