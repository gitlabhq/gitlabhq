import { oauthCallback } from '@gitlab/web-ide';
import { IDE_ELEMENT_ID } from '~/ide/constants';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';

import { getBaseConfig, getOAuthConfig } from './lib/gitlab_web_ide';

export const mountOAuthCallback = async () => {
  const el = document.getElementById(IDE_ELEMENT_ID);

  try {
    await oauthCallback({
      ...(await getBaseConfig()),
      username: gon.current_username,
      auth: getOAuthConfig(el.dataset),
    });
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error(error);

    createAlert({
      message: s__(
        'WebIdeOAuthCallback|Unable to authorize GitLab Web IDE access. For more information, see the developer console.',
      ),
      dismissible: false,
      containerSelector: '.alert-wrapper',
      primaryButton: {
        text: s__('WebIdeOAuthCallback|Close tab'),
        clickHandler: () => window.close(),
      },
    });
  }
};
