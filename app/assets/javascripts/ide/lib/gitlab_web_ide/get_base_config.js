import { cleanEndingSeparator, joinPaths } from '~/lib/utils/url_utility';

const getGitLabUrl = (gitlabPath = '') => {
  const path = joinPaths('/', window.gon.relative_url_root || '', gitlabPath);
  const baseUrlObj = new URL(path, window.location.origin);

  return cleanEndingSeparator(baseUrlObj.href);
};

export const getBaseConfig = () => ({
  // baseUrl - The URL which hosts the Web IDE static web assets
  baseUrl: getGitLabUrl(process.env.GITLAB_WEB_IDE_PUBLIC_PATH),
  // gitlabUrl - The URL for the GitLab instance
  gitlabUrl: getGitLabUrl(''),
});
