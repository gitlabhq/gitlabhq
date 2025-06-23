import { getGitLabUrl } from './get_gitlab_url';

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
});
