import $ from 'jquery';
import initU2F from './u2f';
import U2FRegister from './u2f/register';

export const mount2faAuthentication = () => {
  // Soon this will conditionally mount a webauthn app (see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/26692)
  initU2F();
};

export const mount2faRegistration = () => {
  // Soon this will conditionally mount a webauthn app (see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/26692)
  const u2fRegister = new U2FRegister($('#js-register-u2f'), gon.u2f);
  u2fRegister.start();
};
