export function useMockNavigatorCredentials() {
  let oldNavigatorCredentials;
  let oldPublicKeyCredential;

  beforeEach(() => {
    oldNavigatorCredentials = navigator.credentials;
    oldPublicKeyCredential = window.PublicKeyCredential;
    navigator.credentials = {
      get: jest.fn(),
      create: jest.fn(),
    };
    window.PublicKeyCredential = function MockPublicKeyCredential() {};
  });

  afterEach(() => {
    navigator.credentials = oldNavigatorCredentials;
    window.PublicKeyCredential = oldPublicKeyCredential;
  });
}
