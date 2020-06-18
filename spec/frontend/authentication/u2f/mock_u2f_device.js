/* eslint-disable no-unused-expressions */

export default class MockU2FDevice {
  constructor() {
    this.respondToAuthenticateRequest = this.respondToAuthenticateRequest.bind(this);
    this.respondToRegisterRequest = this.respondToRegisterRequest.bind(this);
    window.u2f || (window.u2f = {});
    window.u2f.register = (appId, registerRequests, signRequests, callback) => {
      this.registerCallback = callback;
    };
    window.u2f.sign = (appId, challenges, signRequests, callback) => {
      this.authenticateCallback = callback;
    };
  }

  respondToRegisterRequest(params) {
    return this.registerCallback(params);
  }

  respondToAuthenticateRequest(params) {
    return this.authenticateCallback(params);
  }
}
