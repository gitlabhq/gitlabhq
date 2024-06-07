export const WEB_IDE_OAUTH_CALLBACK_URL_PATH = '/-/ide/oauth_redirect';

export const getOAuthConfig = ({ clientId }) => {
  if (!clientId) {
    return undefined;
  }

  return {
    type: 'oauth',
    clientId,
    callbackUrl: new URL(WEB_IDE_OAUTH_CALLBACK_URL_PATH, window.location.origin).toString(),
    protectRefreshToken: true,
  };
};
