import { initWebAuthnRegistration } from '~/authentication/webauthn/registration';
import {
  initRecoveryCodes,
  initClose2faSuccessMessage,
  initTwoFactorConfirm,
  initEmailOtpConfirm,
} from '~/authentication/two_factor_auth';

initClose2faSuccessMessage();
initWebAuthnRegistration();
initRecoveryCodes();
initTwoFactorConfirm();
initEmailOtpConfirm();
