import $ from 'jquery';
import initU2F from './u2f';
import initWebauthn from './webauthn';
import U2FRegister from './u2f/register';
import WebAuthnRegister from './webauthn/register';

export const mount2faAuthentication = () => {
  if (gon.webauthn) {
    initWebauthn();
  } else {
    initU2F();
  }
};

export const mount2faRegistration = () => {
  if (gon.webauthn) {
    const webauthnRegister = new WebAuthnRegister($('#js-register-token-2fa'), gon.webauthn);
    webauthnRegister.start();
  } else {
    const u2fRegister = new U2FRegister($('#js-register-token-2fa'), gon.u2f);
    u2fRegister.start();
  }
};
