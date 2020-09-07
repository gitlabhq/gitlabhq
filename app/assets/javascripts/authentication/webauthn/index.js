import $ from 'jquery';
import WebAuthnAuthenticate from './authenticate';

export default () => {
  const webauthnAuthenticate = new WebAuthnAuthenticate(
    $('#js-authenticate-token-2fa'),
    '#js-login-token-2fa-form',
    gon.webauthn,
    document.querySelector('#js-login-2fa-device'),
    document.querySelector('.js-2fa-form'),
  );
  webauthnAuthenticate.start();
};
