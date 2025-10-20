import * as packageJSON from '@gitlab/web-ide/package.json';
import { pingWorkbench } from '@gitlab/web-ide';
import { s__ } from '~/locale';
import { sha256 } from '~/lib/utils/text_utility';
import { joinPaths } from '~/lib/utils/url_utility';
import { getGitLabUrl } from './get_gitlab_url';

/**
 * Builds the URL path that points to the Web IDE extension host
 * assets. If the extension host domain changed in application settings,
 * the Web IDE assumes that the new domain points to the Gitlab instance
 * itself therefore the base path starts with the Gitlab instance root assets
 * path "assets/webpack".
 * @param {Boolean} extensionHostDomainChanged Whether the base extension host domain
 * is not the default value built into the GitLab instance.
 * @returns
 */
const buildBaseAssetsPath = (extensionHostDomainChanged) => {
  const assetsRoot = extensionHostDomainChanged ? '/assets/webpack' : '/';

  return joinPaths(assetsRoot, `gitlab-web-ide-vscode-workbench-${packageJSON.version}`);
};

/**
 * Builds the URL that points to the VSCode extension host service. If instance admin
 * provides a custom the extension host domain, this function prepends `/assets/webpack`
 * to the URL path because it assumes the custom extension host domains points to the
 * GitLab instance.
 *
 * VSCode expects that the extension host domain is a wildcard therefore we insert a placeholder
 * {{uuid}} at the beginning of the domain.
 *
 * @param {String} options.extensionHostDomain Base extension host domain coming from
 * application settings
 * @param {Boolean} options.extensionHostDomainChanged Whether the base extension host domain
 * is not the default value built into the GitLab instance.
 * @returns
 */
const buildExtensionHostUrl = ({ extensionHostDomain, extensionHostDomainChanged }) => {
  const baseAssetsPath = buildBaseAssetsPath(extensionHostDomainChanged);
  const fullAssetsPath = joinPaths(baseAssetsPath, 'vscode');

  const extensionHostUrl = new URL(fullAssetsPath, `https://{{uuid}}.${extensionHostDomain}`);

  return extensionHostUrl.href;
};

const rejectHTTPEmbedderOrigin = () => {
  if (window.location.protocol !== 'https:') {
    throw new Error();
  }
};

/**
 * Builds the URL that points to the VSCode workbench assets. If instance admin
 * provides a custom the extension host domain, this function prepends `/assets/webpack`
 * to the URL path because it assumes the custom extension host domains points to the
 * GitLab instance.
 *
 * The client generates a workbench subdomain based on the GitLab instance domain and the
 * current username.
 *
 * @param {String} options.extensionHostDomain Base extension host domain coming from
 * application settings
 * @param {Boolean} options.extensionHostDomainChanged Whether the base extension host domain
 * is not the default value built into the GitLab instance.
 *
 */
export const buildWorkbenchUrl = async ({ extensionHostDomain, extensionHostDomainChanged }) => {
  const digest = await sha256(`${window.location.origin}-${window.gon.current_username}`);
  const digestShort = digest.slice(0, 30);
  const workbenchUrl = new URL(
    buildBaseAssetsPath(extensionHostDomainChanged),
    `https://workbench-${digestShort}.${extensionHostDomain}`,
  );

  return workbenchUrl.href;
};

/**
 * Retrieves configuration for Web IDE workbench.
 *
 * @param {String} options.extensionHostDomain Base extension host domain coming from
 * application settings
 * @param {Boolean} options.extensionHostDomainChanged Whether the base extension host domain
 * is not the default value built into the GitLab instance.
 *
 * @returns An object containing the following properties
 * - workbenchBaseUrl URL pointing to the origin and base path where the Web IDE's workbench assets are hosted.
 * - extensionsHostBaseUrl URL pointing to the origin and the base path where the Web IDE's extensions host assets are hosted.
 * - crossOriginExtensionHost Boolean specifying whether the extensions host will use cross-origin isolation.
 */
export const getWebIDEWorkbenchConfig = async ({
  extensionHostDomain,
  extensionHostDomainChanged = false,
} = {}) => {
  if (typeof extensionHostDomain !== 'string' || !extensionHostDomain) {
    throw new Error(
      s__(
        'WebIDE|The Web IDE does not have a valid extension host domain and it could not be initialized.',
      ),
    );
  }

  const extensionsHostBaseUrl = buildExtensionHostUrl({
    extensionHostDomain,
    extensionHostDomainChanged,
  });

  try {
    rejectHTTPEmbedderOrigin();

    const workbenchBaseUrl = await buildWorkbenchUrl({
      extensionHostDomain,
      extensionHostDomainChanged,
    });

    await pingWorkbench({
      el: document.body,
      config: { workbenchBaseUrl, gitlabUrl: getGitLabUrl() },
    });

    return {
      workbenchBaseUrl,
      extensionsHostBaseUrl,
      crossOriginExtensionHost: true,
    };
  } catch (e) {
    return {
      workbenchBaseUrl: getGitLabUrl(process.env.GITLAB_WEB_IDE_PUBLIC_PATH),
      crossOriginExtensionHost: false,
    };
  }
};
