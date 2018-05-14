import $ from 'jquery';
import U2FAuthenticate from '../../u2f/authenticate';

export default () => {
  if (!gon.u2f) return;

  const u2fAuthenticate = new U2FAuthenticate(
    $('#js-authenticate-u2f'),
    '#js-login-u2f-form',
    gon.u2f,
    document.querySelector('#js-login-2fa-device'),
    document.querySelector('.js-2fa-form'),
  );
  u2fAuthenticate.start();
  // needed in rspec
  gl.u2fAuthenticate = u2fAuthenticate;
};
