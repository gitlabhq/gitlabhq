import { start } from '@gitlab/web-ide';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import csrf from '~/lib/utils/csrf';
import Tracking from '~/tracking';
import {
  getBaseConfig,
  getOAuthConfig,
  setupRootElement,
  handleTracking,
  handleUpdateUrl,
} from './lib/gitlab_web_ide';
import { GITLAB_WEB_IDE_FEEDBACK_ISSUE } from './constants';
import { renderWebIdeError } from './render_web_ide_error';

const getMRTargetProject = () => {
  const url = new URL(window.location.href);

  return url.searchParams.get('target_project') || '';
};

const getCrossOriginExtensionHostFlagValue = (extensionsGallerySettings) => {
  return (
    extensionsGallerySettings?.enabled ||
    extensionsGallerySettings?.reason === 'opt_in_unset' ||
    extensionsGallerySettings?.reason === 'opt_in_disabled'
  );
};

export const initGitlabWebIDE = async (el) => {
  // what: Pull what we need from the element. We will replace it soon.
  const {
    cspNonce: nonce,
    branchName: ref,
    projectPath,
    filePath,
    mergeRequest: mrId,
    forkInfo: forkInfoJSON,
    editorFont: editorFontJSON,
    codeSuggestionsEnabled,
    extensionsGallerySettings: extensionsGallerySettingsJSON,
    settingsContextHash,
    signOutPath,
  } = el.dataset;

  const rootEl = setupRootElement(el);
  const editorFont = editorFontJSON
    ? convertObjectPropsToCamelCase(JSON.parse(editorFontJSON), { deep: true })
    : null;
  const forkInfo = forkInfoJSON ? JSON.parse(forkInfoJSON) : null;
  const extensionsGallerySettings = extensionsGallerySettingsJSON
    ? convertObjectPropsToCamelCase(JSON.parse(extensionsGallerySettingsJSON), { deep: true })
    : undefined;

  const oauthConfig = getOAuthConfig(el.dataset);
  const httpHeaders = oauthConfig
    ? undefined
    : // Use same headers as defined in axios_utils (not needed in oauth)
      {
        [csrf.headerKey]: csrf.token,
        'X-Requested-With': 'XMLHttpRequest',
      };

  const isLanguageServerEnabled = gon?.features?.webIdeLanguageServer || false;

  try {
    // See ClientOnlyConfig https://gitlab.com/gitlab-org/gitlab-web-ide/-/blob/main/packages/web-ide-types/src/config.ts#L17
    await start(rootEl, {
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
        crossOriginExtensionHost: getCrossOriginExtensionHostFlagValue(extensionsGallerySettings),
        languageServerWebIDE: isLanguageServerEnabled,
      },
      editorFont,
      extensionsGallerySettings,
      settingsContextHash,
      codeSuggestionsEnabled,
      handleContextUpdate: handleUpdateUrl,
      handleTracking,
      // See https://gitlab.com/gitlab-org/gitlab-web-ide/-/blob/main/packages/web-ide-types/src/config.ts#L86
      telemetryEnabled: Tracking.enabled(),
    });
  } catch (error) {
    renderWebIdeError({ error, signOutPath });
  }
};
