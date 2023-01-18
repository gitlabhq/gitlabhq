import { cleanEndingSeparator, joinPaths } from '~/lib/utils/url_utility';

const getBaseUrl = () => {
  const path = joinPaths(
    '/',
    window.gon.relative_url_root || '',
    process.env.GITLAB_WEB_IDE_PUBLIC_PATH,
  );
  const baseUrlObj = new URL(path, window.location.origin);

  return cleanEndingSeparator(baseUrlObj.href);
};

export const getBaseConfig = () => ({
  baseUrl: getBaseUrl(),
  gitlabUrl: window.gon.gitlab_url,
});
