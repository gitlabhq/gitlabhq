import { cleanEndingSeparator, joinPaths } from '~/lib/utils/url_utility';

export const getGitLabUrl = (gitlabPath = '') => {
  // eslint-disable-next-line @gitlab/no-hardcoded-urls -- This is custom logic for the IDE that parses window.location, not generating a specific Rails path
  const path = joinPaths('/', window.gon.relative_url_root || '', gitlabPath);
  const baseUrlObj = new URL(path, window.location.origin);

  return cleanEndingSeparator(baseUrlObj.href);
};
