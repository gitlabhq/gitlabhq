import { getBaseConfig } from '~/ide/lib/gitlab_web_ide/get_base_config';
import { getGitLabUrl } from '~/ide/lib/gitlab_web_ide/get_gitlab_url';

jest.mock('~/ide/lib/gitlab_web_ide/get_gitlab_url');

describe('~/ide/lib/gitlab_web_ide/get_base_config', () => {
  it('returns an object with embedderOriginUrl and gitlabUrl set to result of calling getGitLabUrl', () => {
    const gitlabUrl = 'https://gitlab.example.com';

    getGitLabUrl.mockReturnValue(gitlabUrl);

    expect(getBaseConfig()).toEqual({ embedderOriginUrl: gitlabUrl, gitlabUrl });
  });
});
