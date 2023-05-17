import { getBaseConfig } from '~/ide/lib/gitlab_web_ide/get_base_config';
import { TEST_HOST } from 'helpers/test_constants';

const TEST_GITLAB_WEB_IDE_PUBLIC_PATH = 'test/gitlab-web-ide/public/path';
const TEST_RELATIVE_URL_ROOT = '/gl_rel_root';

describe('~/ide/lib/gitlab_web_ide/get_base_config', () => {
  beforeEach(() => {
    // why: add trailing "/" to test that it gets removed
    process.env.GITLAB_WEB_IDE_PUBLIC_PATH = `${TEST_GITLAB_WEB_IDE_PUBLIC_PATH}/`;
    window.gon.relative_url_root = '';
  });

  it('with default, returns base properties for @gitlab/web-ide config', () => {
    const actual = getBaseConfig();

    expect(actual).toEqual({
      baseUrl: `${TEST_HOST}/${TEST_GITLAB_WEB_IDE_PUBLIC_PATH}`,
      gitlabUrl: TEST_HOST,
    });
  });

  it('with relative_url_root, returns baseUrl with relative url root', () => {
    window.gon.relative_url_root = TEST_RELATIVE_URL_ROOT;

    const actual = getBaseConfig();

    expect(actual).toEqual({
      baseUrl: `${TEST_HOST}${TEST_RELATIVE_URL_ROOT}/${TEST_GITLAB_WEB_IDE_PUBLIC_PATH}`,
      gitlabUrl: `${TEST_HOST}${TEST_RELATIVE_URL_ROOT}`,
    });
  });
});
