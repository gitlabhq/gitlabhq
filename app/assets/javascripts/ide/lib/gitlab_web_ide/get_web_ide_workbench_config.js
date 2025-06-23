import * as packageJSON from '@gitlab/web-ide/package.json';
import { pingWorkbench } from '@gitlab/web-ide';
import { sha256 } from '~/lib/utils/text_utility';
import { getGitLabUrl } from './get_gitlab_url';

const buildExtensionHostUrl = () => {
  const workbenchVersion = packageJSON.version;

  return `https://{{uuid}}.cdn.web-ide.gitlab-static.net/gitlab-web-ide-vscode-workbench-${workbenchVersion}/vscode`;
};

const rejectHTTPEmbedderOrigin = () => {
  if (window.location.protocol !== 'https:') {
    throw new Error();
  }
};

/**
 * Generates the workbench URL for Web IDE
 *
 * Uses the current user's username and the origin to generate a digest
 * to ensure that the URL is unique for each user.
 * @returns {string}
 */
export const buildWorkbenchUrl = async () => {
  const digest = await sha256(`${window.location.origin}-${window.gon.current_username}`);
  const digestShort = digest.slice(0, 30);
  const workbenchVersion = packageJSON.version;

  return `https://workbench-${digestShort}.cdn.web-ide.gitlab-static.net/gitlab-web-ide-vscode-workbench-${workbenchVersion}`;
};

/**
 * Retrieves configuration for Web IDE workbench.
 *
 * @returns An object containing the following properties
 * - workbenchBaseUrl URL pointing to the origin and base path where the Web IDE's workbench assets are hosted.
 * - extensionsHostBaseUrl URL pointing to the origin and the base path where the Web IDE's extensions host assets are hosted.
 * - crossOriginExtensionHost Boolean specifying whether the extensions host will use cross-origin isolation.
 */
export const getWebIDEWorkbenchConfig = async () => {
  const extensionsHostBaseUrl = buildExtensionHostUrl();

  try {
    rejectHTTPEmbedderOrigin();

    const workbenchBaseUrl = await buildWorkbenchUrl();

    await pingWorkbench({ el: document.body, config: { workbenchBaseUrl } });

    return {
      workbenchBaseUrl,
      extensionsHostBaseUrl,
      crossOriginExtensionHost: true,
      featureFlags: {
        crossOriginExtensionHost: true,
      },
    };
  } catch (e) {
    return {
      workbenchBaseUrl: getGitLabUrl(process.env.GITLAB_WEB_IDE_PUBLIC_PATH),
      crossOriginExtensionHost: false,
      featureFlags: {
        crossOriginExtensionHost: false,
      },
    };
  }
};
