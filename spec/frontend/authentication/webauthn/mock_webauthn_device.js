/* eslint-disable no-unused-expressions */

export default class MockWebAuthnDevice {
  constructor() {
    this.respondToAuthenticateRequest = this.respondToAuthenticateRequest.bind(this);
    this.respondToRegisterRequest = this.respondToRegisterRequest.bind(this);
    window.navigator.credentials || (window.navigator.credentials = {});
    window.navigator.credentials.create = () =>
      new Promise((resolve, reject) => {
        this.registerCallback = resolve;
        this.registerRejectCallback = reject;
      });
    window.navigator.credentials.get = () =>
      new Promise((resolve, reject) => {
        this.authenticateCallback = resolve;
        this.authenticateRejectCallback = reject;
      });
  }

  respondToRegisterRequest(params) {
    return this.registerCallback(params);
  }

  respondToAuthenticateRequest(params) {
    return this.authenticateCallback(params);
  }

  rejectRegisterRequest(params) {
    return this.registerRejectCallback(params);
  }

  rejectAuthenticateRequest(params) {
    return this.authenticateRejectCallback(params);
  }
}
