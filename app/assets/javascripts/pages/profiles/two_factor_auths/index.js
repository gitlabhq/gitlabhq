import { initWebAuthnRegistration } from '~/authentication/webauthn/registration';
import { initRecoveryCodes, initTwoFactorConfirm } from '~/authentication/two_factor_auth';

initWebAuthnRegistration();
initRecoveryCodes();
initTwoFactorConfirm();
