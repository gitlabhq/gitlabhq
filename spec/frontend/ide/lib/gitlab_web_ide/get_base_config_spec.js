import * as packageJSON from '@gitlab/web-ide/package.json';
import {
  getBaseConfig,
  generateWorkbenchSubdomain,
} from '~/ide/lib/gitlab_web_ide/get_base_config';
import { isMultiDomainEnabled } from '~/ide/lib/gitlab_web_ide/is_multi_domain_enabled';
import { TEST_HOST } from 'helpers/test_constants';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';

const TEST_GITLAB_WEB_IDE_PUBLIC_PATH = 'test/gitlab-web-ide/public/path';
const TEST_RELATIVE_URL_ROOT = '/gl_rel_root';

jest.mock('~/ide/lib/gitlab_web_ide/is_multi_domain_enabled');

describe('~/ide/lib/gitlab_web_ide/get_base_config', () => {
  useMockLocationHelper();

  beforeEach(() => {
    // why: add trailing "/" to test that it gets removed
    process.env.GITLAB_WEB_IDE_PUBLIC_PATH = `${TEST_GITLAB_WEB_IDE_PUBLIC_PATH}/`;
    window.gon.relative_url_root = '';
  });

  it('with default, returns base properties for @gitlab/web-ide config', () => {
    const actual = getBaseConfig();

    expect(actual).toEqual({
      workbenchBaseUrl: `${TEST_HOST}/${TEST_GITLAB_WEB_IDE_PUBLIC_PATH}`,
      embedderOriginUrl: TEST_HOST,
      extensionsHostBaseUrl:
        'https://{{uuid}}.cdn.web-ide.gitlab-static.net/web-ide-vscode/{{quality}}/{{commit}}',
      gitlabUrl: TEST_HOST,
    });
  });

  it('with relative_url_root, returns baseUrl with relative url root', () => {
    window.gon.relative_url_root = TEST_RELATIVE_URL_ROOT;

    const actual = getBaseConfig();

    expect(actual).toEqual({
      workbenchBaseUrl: `${TEST_HOST}${TEST_RELATIVE_URL_ROOT}/${TEST_GITLAB_WEB_IDE_PUBLIC_PATH}`,
      embedderOriginUrl: `${TEST_HOST}${TEST_RELATIVE_URL_ROOT}`,
      extensionsHostBaseUrl:
        'https://{{uuid}}.cdn.web-ide.gitlab-static.net/web-ide-vscode/{{quality}}/{{commit}}',
      gitlabUrl: `${TEST_HOST}${TEST_RELATIVE_URL_ROOT}`,
    });
  });

  describe('generateWorkbenchSubdomain', () => {
    it.each`
      origin                       | currentUsername | result
      ${'https://example.com'}     | ${'foobar'}     | ${'aHR0cHM6Ly9leGFtcGxlLmNvbS1mb29iYXI'}
      ${'https://ide.example.com'} | ${'barfoo'}     | ${'aHR0cHM6Ly9pZGUuZXhhbXBsZS5jb20tYmFyZm9v'}
      ${'https://ide.example.com'} | ${'bar.foo'}    | ${'aHR0cHM6Ly9pZGUuZXhhbXBsZS5jb20tYmFyLmZvbw'}
      ${'https://ide.example.com'} | ${'bar+foo'}    | ${'aHR0cHM6Ly9pZGUuZXhhbXBsZS5jb20tYmFyK2Zvbw'}
    `(
      'returns $result when origin is $origin and currentUsername is $currentUsername',
      ({ origin, currentUsername, result }) => {
        window.location.origin = origin;
        window.gon.current_username = currentUsername;

        expect(generateWorkbenchSubdomain()).toBe(result);
      },
    );
  });

  describe('with multi-domain enabled', () => {
    beforeEach(() => {
      window.gon.current_username = 'foobar';
      isMultiDomainEnabled.mockReturnValue(true);
    });

    it('returns workbenchBaseUrl with external domain and base64 encoded subdomain', () => {
      expect(getBaseConfig().workbenchBaseUrl).toBe(
        `https://workbench-${generateWorkbenchSubdomain()}.cdn.web-ide.gitlab-static.net/gitlab-web-ide-vscode-workbench-${packageJSON.version}`,
      );
    });

    it('returns extensionsHostBaseUrl with external domain and placeholder uuid subdomain', () => {
      expect(getBaseConfig().extensionsHostBaseUrl).toBe(
        `https://{{uuid}}.cdn.web-ide.gitlab-static.net/gitlab-web-ide-vscode-workbench-${packageJSON.version}/vscode`,
      );
    });

    it('returns shared base properties', () => {
      expect(getBaseConfig()).toStrictEqual(
        expect.objectContaining({
          embedderOriginUrl: TEST_HOST,
          gitlabUrl: TEST_HOST,
        }),
      );
    });
  });
});
