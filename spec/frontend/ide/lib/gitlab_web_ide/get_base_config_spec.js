import { getBaseConfig } from '~/ide/lib/gitlab_web_ide/get_base_config';
import { TEST_HOST } from 'helpers/test_constants';

const TEST_GITLAB_WEB_IDE_PUBLIC_PATH = 'test/gitlab-web-ide/public/path';
const TEST_GITLAB_URL = 'https://gdk.test/';

describe('~/ide/lib/gitlab_web_ide/get_base_config', () => {
  it('returns base properties for @gitlab/web-ide config', () => {
    // why: add trailing "/" to test that it gets removed
    process.env.GITLAB_WEB_IDE_PUBLIC_PATH = `${TEST_GITLAB_WEB_IDE_PUBLIC_PATH}/`;
    window.gon.gitlab_url = TEST_GITLAB_URL;

    // act
    const actual = getBaseConfig();

    // asset
    expect(actual).toEqual({
      baseUrl: `${TEST_HOST}/${TEST_GITLAB_WEB_IDE_PUBLIC_PATH}`,
      gitlabUrl: TEST_GITLAB_URL,
    });
  });
});
