import { initWebAuthnRegistration } from '~/authentication/webauthn/registration';
import {
  initRecoveryCodes,
  initTwoFactorConfirm,
  initEmailOtpConfirm,
} from '~/authentication/two_factor_auth';

initWebAuthnRegistration();
initRecoveryCodes();
initTwoFactorConfirm();
initEmailOtpConfirm();
