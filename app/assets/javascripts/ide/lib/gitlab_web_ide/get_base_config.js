import { cleanEndingSeparator, joinPaths } from '~/lib/utils/url_utility';

const getGitLabUrl = (gitlabPath = '') => {
  const path = joinPaths('/', window.gon.relative_url_root || '', gitlabPath);
  const baseUrlObj = new URL(path, window.location.origin);

  return cleanEndingSeparator(baseUrlObj.href);
};

export const getBaseConfig = () => ({
  /**
   * URL pointing to the origin and base path where the
   * Web IDE's workbench assets are hosted.
   */
  workbenchBaseUrl: getGitLabUrl(process.env.GITLAB_WEB_IDE_PUBLIC_PATH),

  /**
   * URL pointing to the system embedding the Web IDE. Most of the
   * time, but not necessarily, is a GitLab instance.
   */
  embedderOriginUrl: getGitLabUrl(''),

  /**
   * URL pointing to the origin and the base path where
   * the Web IDE's extensions host assets are hosted.
   */
  extensionsHostBaseUrl:
    'https://{{uuid}}.cdn.web-ide.gitlab-static.net/web-ide-vscode/{{quality}}/{{commit}}',

  /**
   * URL pointing to the origin of the GitLab instance.
   * It is used for API access.
   */
  gitlabUrl: getGitLabUrl(''),
});
