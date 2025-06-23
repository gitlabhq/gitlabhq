import { getGitLabUrl } from '~/ide/lib/gitlab_web_ide/get_gitlab_url';
import { TEST_HOST } from 'helpers/test_constants';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';

describe('~/ide/lib/gitlab_web_ide/get_gitlab_url', () => {
  useMockLocationHelper();

  const TEST_GITLAB_WEB_IDE_PUBLIC_PATH = 'test/gitlab-web-ide/public/path';
  const TEST_RELATIVE_URL_ROOT = 'gl_rel_root';

  beforeEach(() => {
    window.location.origin = TEST_HOST;
  });

  it.each`
    relativeUrlRoot           | gitlabPath                         | result
    ${''}                     | ${''}                              | ${TEST_HOST}
    ${TEST_RELATIVE_URL_ROOT} | ${''}                              | ${`${TEST_HOST}/${TEST_RELATIVE_URL_ROOT}`}
    ${''}                     | ${TEST_GITLAB_WEB_IDE_PUBLIC_PATH} | ${`${TEST_HOST}/${TEST_GITLAB_WEB_IDE_PUBLIC_PATH}`}
    ${TEST_RELATIVE_URL_ROOT} | ${TEST_GITLAB_WEB_IDE_PUBLIC_PATH} | ${`${TEST_HOST}/${TEST_RELATIVE_URL_ROOT}/${TEST_GITLAB_WEB_IDE_PUBLIC_PATH}`}
  `(
    'with relativeUrlRoot=$relativeUrlRoot, gitlabPath=$gitlabPath returns $result',
    async ({ relativeUrlRoot, gitlabPath, result }) => {
      window.gon.relative_url_root = relativeUrlRoot;

      const actual = await getGitLabUrl(gitlabPath);

      expect(actual).toEqual(result);
    },
  );
});
