import * as packageJSON from '@gitlab/web-ide/package.json';
import {
  getBaseConfig,
  generateWorkbenchSubdomain,
} from '~/ide/lib/gitlab_web_ide/get_base_config';
import { isMultiDomainEnabled } from '~/ide/lib/gitlab_web_ide/is_multi_domain_enabled';
import { TEST_HOST } from 'helpers/test_constants';
import { stubCrypto } from 'helpers/crypto';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';

const TEST_GITLAB_WEB_IDE_PUBLIC_PATH = 'test/gitlab-web-ide/public/path';
const TEST_RELATIVE_URL_ROOT = '/gl_rel_root';

jest.mock('~/ide/lib/gitlab_web_ide/is_multi_domain_enabled');

describe('~/ide/lib/gitlab_web_ide/get_base_config', () => {
  useMockLocationHelper();
  stubCrypto();

  beforeEach(() => {
    // why: add trailing "/" to test that it gets removed
    process.env.GITLAB_WEB_IDE_PUBLIC_PATH = `${TEST_GITLAB_WEB_IDE_PUBLIC_PATH}/`;
    window.gon.relative_url_root = '';
  });

  it('with default, returns base properties for @gitlab/web-ide config', async () => {
    const actual = await getBaseConfig();

    expect(actual).toEqual({
      workbenchBaseUrl: `${TEST_HOST}/${TEST_GITLAB_WEB_IDE_PUBLIC_PATH}`,
      embedderOriginUrl: TEST_HOST,
      extensionsHostBaseUrl:
        'https://{{uuid}}.cdn.web-ide.gitlab-static.net/web-ide-vscode/{{quality}}/{{commit}}',
      gitlabUrl: TEST_HOST,
    });
  });

  it('with relative_url_root, returns baseUrl with relative url root', async () => {
    window.gon.relative_url_root = TEST_RELATIVE_URL_ROOT;

    const actual = await getBaseConfig();

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
      origin                       | currentUsername               | result
      ${'https://example.com'}     | ${'foobar'}                   | ${'ee2af4a14057872bd8c7463645f503'}
      ${'https://ide.example.com'} | ${'barfoo'}                   | ${'ae3f10e196eac8ef4045e3ec9ba4a5'}
      ${'https://ide.example.com'} | ${'bar.foo'}                  | ${'5bfda1a3ce2b366a1491aba48eba08'}
      ${'https://ide.example.com'} | ${'bar+foo'}                  | ${'b6a09e91b3b97cc3b4f70cf6dfa1dd'}
      ${'https://ide.example.com'} | ${'bar+foo+bar+foo+bar+foo '} | ${'f16f0302f14b7026753d426915bef7'}
    `(
      'returns $result when origin is $origin and currentUsername is $currentUsername',
      async ({ origin, currentUsername, result }) => {
        window.location.origin = origin;
        window.gon.current_username = currentUsername;

        const subdomain = await generateWorkbenchSubdomain();

        expect(subdomain).toBe(result);
        expect(subdomain).toHaveLength(30);
      },
    );
  });

  describe('with multi-domain enabled', () => {
    beforeEach(() => {
      window.gon.current_username = 'foobar';
      isMultiDomainEnabled.mockReturnValue(true);
    });

    it('returns workbenchBaseUrl with external domain and base64 encoded subdomain', async () => {
      expect((await getBaseConfig()).workbenchBaseUrl).toBe(
        `https://workbench-${await generateWorkbenchSubdomain()}.cdn.web-ide.gitlab-static.net/gitlab-web-ide-vscode-workbench-${packageJSON.version}`,
      );
    });

    it('returns extensionsHostBaseUrl with external domain and placeholder uuid subdomain', async () => {
      expect((await getBaseConfig()).extensionsHostBaseUrl).toBe(
        `https://{{uuid}}.cdn.web-ide.gitlab-static.net/gitlab-web-ide-vscode-workbench-${packageJSON.version}/vscode`,
      );
    });

    it('returns shared base properties', async () => {
      expect(await getBaseConfig()).toStrictEqual(
        expect.objectContaining({
          embedderOriginUrl: TEST_HOST,
          gitlabUrl: TEST_HOST,
        }),
      );
    });
  });
});
