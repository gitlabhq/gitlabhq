import { start } from '@gitlab/web-ide';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import csrf from '~/lib/utils/csrf';
import Tracking from '~/tracking';
import { getLineRangeFromHash } from '~/lib/utils/url_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import {
  getBaseConfig,
  getOAuthConfig,
  setupIdeContainer,
  handleTracking,
  handleUpdateUrl,
  getWebIDEWorkbenchConfig,
} from './lib/gitlab_web_ide';
import { GITLAB_WEB_IDE_FEEDBACK_ISSUE } from './constants';
import { renderWebIdeError } from './render_web_ide_error';

// This module imports no Vue, so it acts as a barrier that stops the page
// entrypoint's Vue 3 infection from reaching the error app below it. Ask for the
// Vue 3 copy explicitly instead, keeping it behind the flag so the build-time
// `?vue3` suffix cannot leak Vue 3 to users with the flag off.
// Remove with vue3_migrate_web_ide: https://gitlab.com/gitlab-org/gitlab/-/work_items/618744
const resolveRenderWebIdeError = async () => {
  if (!gon.features?.vue3MigrateWebIde) {
    return renderWebIdeError;
  }

  try {
    const vue3Module = await import('./render_web_ide_error?vue3');

    return vue3Module.renderWebIdeError;
  } catch (error) {
    Sentry.captureException(error);

    return renderWebIdeError;
  }
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
    filePath,
    mergeRequest: mrId,
    forkInfo: forkInfoJSON,
    editorFont: editorFontJSON,
    codeSuggestionsEnabled,
    extensionMarketplaceSettings: extensionMarketplaceSettingsJSON,
    settingsContextHash,
    signOutPath,
    extensionHostDomain,
    extensionHostDomainChanged,
    workbenchSecret,
    isSingleOriginFallbackEnabled,
  } = el.dataset;

  try {
    const webIdeWorkbenchConfig = await getWebIDEWorkbenchConfig({
      extensionHostDomain,
      isSingleOriginFallbackEnabled: parseBoolean(isSingleOriginFallbackEnabled),
      extensionHostDomainChanged: parseBoolean(extensionHostDomainChanged),
      workbenchSecret,
    });
    const container = setupIdeContainer(el);
    const editorFont = editorFontJSON
      ? convertObjectPropsToCamelCase(JSON.parse(editorFontJSON), { deep: true })
      : null;
    const forkInfo = forkInfoJSON ? JSON.parse(forkInfoJSON) : null;
    const extensionMarketplaceSettings = extensionMarketplaceSettingsJSON
      ? convertObjectPropsToCamelCase(JSON.parse(extensionMarketplaceSettingsJSON), { deep: true })
      : undefined;

    const oauthConfig = getOAuthConfig(el.dataset);
    const httpHeaders = oauthConfig
      ? undefined
      : // Use same headers as defined in axios_utils (not needed in oauth)
        {
          [csrf.headerKey]: csrf.token,
          'X-Requested-With': 'XMLHttpRequest',
        };

    const lineRange = getLineRangeFromHash();

    // See ClientOnlyConfig https://gitlab.com/gitlab-org/gitlab-web-ide/-/blob/main/packages/web-ide-types/src/config.ts#L17
    const { ready } = await start(container.element, {
      ...getBaseConfig(),
      ...webIdeWorkbenchConfig,
      nonce,
      httpHeaders,
      auth: oauthConfig,
      projectPath,
      ref,
      filePath,
      lineRange,
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
        languageServerWebIDE: true,
        additionalSourceControlOperations: true,
      },
      editorFont,
      extensionsGallerySettings: extensionMarketplaceSettings,
      settingsContextHash,
      codeSuggestionsEnabled,
      handleContextUpdate: handleUpdateUrl,
      handleTracking,
      // See https://gitlab.com/gitlab-org/gitlab-web-ide/-/blob/main/packages/web-ide-types/src/config.ts#L86
      telemetryEnabled: Tracking.enabled(),
    });

    await ready;

    container.show();
  } catch (error) {
    const render = await resolveRenderWebIdeError();

    render({ error, signOutPath });
  }
};
