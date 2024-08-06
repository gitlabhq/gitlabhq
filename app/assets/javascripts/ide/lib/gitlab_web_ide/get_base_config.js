import { cleanEndingSeparator, joinPaths } from '~/lib/utils/url_utility';

const getGitLabUrl = (gitlabPath = '') => {
  const path = joinPaths('/', window.gon.relative_url_root || '', gitlabPath);
  const baseUrlObj = new URL(path, window.location.origin);

  return baseUrlObj.href;
};

export const getBaseConfig = () => ({
  // baseUrl - The URL which hosts the Web IDE static web assets
  baseUrl: cleanEndingSeparator(getGitLabUrl(process.env.GITLAB_WEB_IDE_PUBLIC_PATH)),
  // gitlabUrl - The URL for the GitLab instance. End with trailing slash so URL's are built properly in relative_url_root.
  gitlabUrl: getGitLabUrl('/'),
});
