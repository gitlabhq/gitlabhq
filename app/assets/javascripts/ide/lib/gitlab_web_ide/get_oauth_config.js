import { getOAuthCallbackUrl } from './oauth_callback_urls';

export const getOAuthConfig = ({ clientId }) => {
  if (!clientId) {
    return undefined;
  }

  return {
    type: 'oauth',
    clientId,
    callbackUrl: getOAuthCallbackUrl(),
    protectRefreshToken: true,
  };
};
