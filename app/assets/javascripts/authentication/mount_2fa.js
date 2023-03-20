import { initWebauthnAuthenticate, initWebauthnRegister } from './webauthn';

export const mount2faAuthentication = () => {
  initWebauthnAuthenticate();
};

export const mount2faRegistration = () => {
  initWebauthnRegister();
};
