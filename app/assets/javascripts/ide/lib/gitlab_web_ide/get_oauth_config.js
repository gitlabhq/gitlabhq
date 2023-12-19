export const getOAuthConfig = ({ clientId, callbackUrl }) => {
  if (!clientId) {
    return undefined;
  }

  return {
    type: 'oauth',
    clientId,
    callbackUrl,
    protectRefreshToken: true,
  };
};
