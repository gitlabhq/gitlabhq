import { start } from '@gitlab/web-ide';
import { __ } from '~/locale';
import { cleanLeadingSeparator } from '~/lib/utils/url_utility';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_action';
import { createAndSubmitForm } from '~/lib/utils/create_and_submit_form';
import csrf from '~/lib/utils/csrf';
import { getBaseConfig } from './lib/gitlab_web_ide/get_base_config';
import { setupRootElement } from './lib/gitlab_web_ide/setup_root_element';
import { GITLAB_WEB_IDE_FEEDBACK_ISSUE } from './constants';
import { handleTracking } from './lib/gitlab_web_ide/handle_tracking_event';

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

const getMRTargetProject = () => {
  const url = new URL(window.location.href);

  return url.searchParams.get('target_project') || '';
};

export const initGitlabWebIDE = async (el) => {
  // what: Pull what we need from the element. We will replace it soon.
  const {
    cspNonce: nonce,
    branchName: ref,
    projectPath,
    ideRemotePath,
    filePath,
    mergeRequest: mrId,
    forkInfo: forkInfoJSON,
    editorFontSrcUrl,
    editorFontFormat,
    editorFontFamily,
  } = el.dataset;

  const rootEl = setupRootElement(el);
  const forkInfo = forkInfoJSON ? JSON.parse(forkInfoJSON) : null;

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
    filePath,
    mrId,
    mrTargetProject: getMRTargetProject(),
    // note: At the time of writing this, forkInfo isn't expected by `@gitlab/web-ide`,
    //       but it will be soon.
    forkInfo,
    links: {
      feedbackIssue: GITLAB_WEB_IDE_FEEDBACK_ISSUE,
      userPreferences: el.dataset.userPreferencesPath,
      signIn: el.dataset.signInPath,
    },
    editorFont: {
      srcUrl: editorFontSrcUrl,
      fontFamily: editorFontFamily,
      format: editorFontFormat,
    },
    handleTracking,
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
