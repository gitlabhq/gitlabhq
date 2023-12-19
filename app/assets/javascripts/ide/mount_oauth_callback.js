import { oauthCallback } from '@gitlab/web-ide';
import { getBaseConfig, getOAuthConfig } from './lib/gitlab_web_ide';

export const mountOAuthCallback = () => {
  const el = document.getElementById('ide');

  return oauthCallback({
    ...getBaseConfig(),
    username: gon.current_username,
    auth: getOAuthConfig(el.dataset),
  });
};
