import { mount2faRegistration } from '~/authentication/mount_2fa';
import { initWebAuthnRegistration } from '~/authentication/webauthn/registration';
import { initRecoveryCodes, initTwoFactorConfirm } from '~/authentication/two_factor_auth';

mount2faRegistration();
initWebAuthnRegistration();
initRecoveryCodes();
initTwoFactorConfirm();
