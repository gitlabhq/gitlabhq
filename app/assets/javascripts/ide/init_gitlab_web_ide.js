import { start } from '@gitlab/web-ide';
import { __ } from '~/locale';
import { cleanLeadingSeparator } from '~/lib/utils/url_utility';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_action';
import { createAndSubmitForm } from '~/lib/utils/create_and_submit_form';
import csrf from '~/lib/utils/csrf';
import { getBaseConfig } from './lib/gitlab_web_ide/get_base_config';
import { setupRootElement } from './lib/gitlab_web_ide/setup_root_element';
import { GITLAB_WEB_IDE_FEEDBACK_ISSUE } from './constants';

const buildRemoteIdeURL = (ideRemotePath, remoteHost, remotePathArg) => {
  const remotePath = cleanLeadingSeparator(remotePathArg);

  const replacers = {
    ':remote_host': encodeURIComponent(remoteHost),
    ':remote_path': encodeURIComponent(remotePath).replaceAll('%2F', '/'),
  };

  // why: Use the function callback of "replace" so we replace both keys at once
  return ideRemotePath.replace(/(:remote_host|:remote_path)/g, (key) => {
    return replacers[key];
  });
};

export const initGitlabWebIDE = async (el) => {
  // what: Pull what we need from the element. We will replace it soon.
  const { cspNonce: nonce, branchName: ref, projectPath, ideRemotePath } = el.dataset;

  const rootEl = setupRootElement(el);

  // See ClientOnlyConfig https://gitlab.com/gitlab-org/gitlab-web-ide/-/blob/main/packages/web-ide-types/src/config.ts#L17
  start(rootEl, {
    ...getBaseConfig(),
    nonce,
    // Use same headers as defined in axios_utils
    httpHeaders: {
      [csrf.headerKey]: csrf.token,
      'X-Requested-With': 'XMLHttpRequest',
    },
    projectPath,
    ref,
    links: {
      feedbackIssue: GITLAB_WEB_IDE_FEEDBACK_ISSUE,
      userPreferences: el.dataset.userPreferencesPath,
    },
    async handleStartRemote({ remoteHost, remotePath, connectionToken }) {
      const confirmed = await confirmAction(
        __('Are you sure you want to leave the Web IDE? All unsaved changes will be lost.'),
        {
          primaryBtnText: __('Start remote connection'),
          cancelBtnText: __('Continue editing'),
        },
      );

      if (!confirmed) {
        return;
      }

      createAndSubmitForm({
        url: buildRemoteIdeURL(ideRemotePath, remoteHost, remotePath),
        data: {
          connection_token: connectionToken,
          return_url: window.location.href,
        },
      });
    },
  });
};
