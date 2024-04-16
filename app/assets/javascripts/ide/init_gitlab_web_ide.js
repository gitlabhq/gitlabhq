import { start } from '@gitlab/web-ide';
import { __ } from '~/locale';
import { cleanLeadingSeparator } from '~/lib/utils/url_utility';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_action';
import { createAndSubmitForm } from '~/lib/utils/create_and_submit_form';
import csrf from '~/lib/utils/csrf';
import Tracking from '~/tracking';
import {
  getBaseConfig,
  getOAuthConfig,
  setupRootElement,
  handleTracking,
} from './lib/gitlab_web_ide';
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
    editorFont: editorFontJSON,
    codeSuggestionsEnabled,
  } = el.dataset;

  const rootEl = setupRootElement(el);
  const editorFont = editorFontJSON
    ? convertObjectPropsToCamelCase(JSON.parse(editorFontJSON), { deep: true })
    : null;
  const forkInfo = forkInfoJSON ? JSON.parse(forkInfoJSON) : null;

  const oauthConfig = getOAuthConfig(el.dataset);
  const httpHeaders = oauthConfig
    ? undefined
    : // Use same headers as defined in axios_utils (not needed in oauth)
      {
        [csrf.headerKey]: csrf.token,
        'X-Requested-With': 'XMLHttpRequest',
      };

  // See ClientOnlyConfig https://gitlab.com/gitlab-org/gitlab-web-ide/-/blob/main/packages/web-ide-types/src/config.ts#L17
  start(rootEl, {
    ...getBaseConfig(),
    nonce,
    httpHeaders,
    auth: oauthConfig,
    projectPath,
    ref,
    filePath,
    mrId,
    mrTargetProject: getMRTargetProject(),
    forkInfo,
    username: gon.current_username,
    links: {
      feedbackIssue: GITLAB_WEB_IDE_FEEDBACK_ISSUE,
      userPreferences: el.dataset.userPreferencesPath,
      signIn: el.dataset.signInPath,
    },
    featureFlags: {
      settingsSync: true,
    },
    editorFont,
    codeSuggestionsEnabled,
    handleTracking,
    // See https://gitlab.com/gitlab-org/gitlab-web-ide/-/blob/main/packages/web-ide-types/src/config.ts#L86
    telemetryEnabled: Tracking.enabled(),
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
