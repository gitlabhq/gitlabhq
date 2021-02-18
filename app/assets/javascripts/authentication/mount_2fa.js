import $ from 'jquery';
import initU2F from './u2f';
import U2FRegister from './u2f/register';
import initWebauthn from './webauthn';
import WebAuthnRegister from './webauthn/register';

export const mount2faAuthentication = () => {
  if (gon.webauthn) {
    initWebauthn();
  } else {
    initU2F();
  }
};

export const mount2faRegistration = () => {
  const el = $('#js-register-token-2fa');

  if (!el.length) {
    return;
  }

  if (gon.webauthn) {
    const webauthnRegister = new WebAuthnRegister(el, gon.webauthn);
    webauthnRegister.start();
  } else {
    const u2fRegister = new U2FRegister(el, gon.u2f);
    u2fRegister.start();
  }
};
