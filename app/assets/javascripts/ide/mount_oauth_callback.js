import { oauthCallback } from '@gitlab/web-ide';
import { IDE_ELEMENT_ID } from '~/ide/constants';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';

import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { getBaseConfig, getOAuthConfig } from './lib/gitlab_web_ide';

// `~/alert` is a Vue app root, and this module imports no Vue of its own, so the
// page entrypoint's Vue 3 infection stops here and never reaches the alert. Ask
// for the Vue 3 copy explicitly, behind the flag so the build-time `?vue3`
// suffix cannot leak Vue 3 to users with the flag off.
// Remove with vue3_migrate_web_ide: https://gitlab.com/gitlab-org/gitlab/-/work_items/618744
const resolveCreateAlert = async () => {
  if (!gon.features?.vue3MigrateWebIde) {
    return createAlert;
  }

  try {
    const vue3Module = await import('~/alert?vue3');

    return vue3Module.createAlert;
  } catch (error) {
    Sentry.captureException(error);

    return createAlert;
  }
};

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

    const alert = await resolveCreateAlert();

    alert({
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
