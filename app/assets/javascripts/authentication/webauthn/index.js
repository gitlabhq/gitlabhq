import $ from 'jquery';
import WebAuthnAuthenticate from './authenticate';
import WebAuthnRegister from './register';

export const initWebauthnAuthenticate = () => {
  if (!gon.webauthn) {
    return;
  }

  const webauthnAuthenticate = new WebAuthnAuthenticate(
    $('#js-authenticate-token-2fa'),
    '#js-login-token-2fa-form',
    gon.webauthn,
    document.querySelector('#js-login-2fa-device'),
    document.querySelector('.js-2fa-form'),
  );
  webauthnAuthenticate.start();
};

export const initWebauthnRegister = () => {
  const el = $('#js-register-token-2fa');

  if (!el.length) {
    return;
  }

  const webauthnRegister = new WebAuthnRegister(el, gon.webauthn);
  webauthnRegister.start();
};
