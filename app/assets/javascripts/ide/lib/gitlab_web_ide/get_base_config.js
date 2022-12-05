import { cleanEndingSeparator } from '~/lib/utils/url_utility';

const getBaseUrl = () => {
  const baseUrlObj = new URL(process.env.GITLAB_WEB_IDE_PUBLIC_PATH, window.location.origin);

  return cleanEndingSeparator(baseUrlObj.href);
};

export const getBaseConfig = () => ({
  baseUrl: getBaseUrl(),
  gitlabUrl: window.gon.gitlab_url,
});
