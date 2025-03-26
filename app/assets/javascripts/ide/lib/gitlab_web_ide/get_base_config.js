import * as packageJSON from '@gitlab/web-ide/package.json';
import { cleanEndingSeparator, joinPaths } from '~/lib/utils/url_utility';
import { isMultiDomainEnabled } from './is_multi_domain_enabled';

const getGitLabUrl = (gitlabPath = '') => {
  const path = joinPaths('/', window.gon.relative_url_root || '', gitlabPath);
  const baseUrlObj = new URL(path, window.location.origin);

  return cleanEndingSeparator(baseUrlObj.href);
};

/**
 * Generates a base64 string based on the GitLab instance origin and the current username.
 * @returns {string}
 */
export const generateWorkbenchSubdomain = () =>
  btoa(`${window.location.origin}-${window.gon.current_username}`).replace(/\W+/g, '');

const getWorkbenchUrlsMultiDomain = () => {
  const workbenchVersion = packageJSON.version;

  return {
    /**
     * URL pointing to the origin and base path where the
     * Web IDE's workbench assets are hosted.
     */
    workbenchBaseUrl: `https://workbench-${generateWorkbenchSubdomain()}.cdn.web-ide.gitlab-static.net/gitlab-web-ide-vscode-workbench-${workbenchVersion}`,

    /**
     * URL pointing to the origin and the base path where
     * the Web IDE's extensions host assets are hosted.
     */
    extensionsHostBaseUrl: `https://{{uuid}}.cdn.web-ide.gitlab-static.net/gitlab-web-ide-vscode-workbench-${workbenchVersion}/vscode`,
  };
};

const getWorkbenchUrlsSingleDomain = () => ({
  /**
   * URL pointing to the origin and base path where the
   * Web IDE's workbench assets are hosted.
   */
  workbenchBaseUrl: getGitLabUrl(process.env.GITLAB_WEB_IDE_PUBLIC_PATH),

  /**
   * URL pointing to the origin and the base path where
   * the Web IDE's extensions host assets are hosted.
   */
  extensionsHostBaseUrl:
    'https://{{uuid}}.cdn.web-ide.gitlab-static.net/web-ide-vscode/{{quality}}/{{commit}}',
});

const getWorkbenchUrls = () =>
  isMultiDomainEnabled() ? getWorkbenchUrlsMultiDomain() : getWorkbenchUrlsSingleDomain();

export const getBaseConfig = () => ({
  /**
   * URL pointing to the system embedding the Web IDE. Most of the
   * time, but not necessarily, is a GitLab instance.
   */
  embedderOriginUrl: getGitLabUrl(''),

  /**
   * URL pointing to the origin of the GitLab instance.
   * It is used for API access.
   */
  gitlabUrl: getGitLabUrl(''),

  ...getWorkbenchUrls(),
});
