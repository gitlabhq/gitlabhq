import * as packageJSON from '@gitlab/web-ide/package.json';
import { pingWorkbench } from '@gitlab/web-ide';
import { stubCrypto } from 'helpers/crypto';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import {
  buildWorkbenchUrl,
  getWebIDEWorkbenchConfig,
} from '~/ide/lib/gitlab_web_ide/get_web_ide_workbench_config';
import { getGitLabUrl } from '~/ide/lib/gitlab_web_ide/get_gitlab_url';

jest.mock('@gitlab/web-ide');
jest.mock('~/ide/lib/gitlab_web_ide/get_gitlab_url');

describe('~/ide/lib/gitlab_web_ide/get_base_config', () => {
  const TEST_GITLAB_WEB_IDE_PUBLIC_PATH = 'test/gitlab-web-ide/public/path';
  const GITLAB_URL = 'https://gitlab.example.com';
  const DEFAULT_PARAMETERS = {
    extensionHostDomain: 'web-ide-example.net',
    extensionHostDomainChanged: false,
  };

  useMockLocationHelper();
  stubCrypto();

  beforeEach(() => {
    getGitLabUrl.mockReturnValue(GITLAB_URL);

    process.env.GITLAB_WEB_IDE_PUBLIC_PATH = TEST_GITLAB_WEB_IDE_PUBLIC_PATH;
    window.gon.relative_url_root = '';
    window.location.protocol = 'https:';
  });

  describe('getWebIDEWorkbenchConfig', () => {
    describe('when embedder protocol is not https', () => {
      let config;

      beforeEach(async () => {
        window.location.protocol = 'http:';

        config = await getWebIDEWorkbenchConfig(DEFAULT_PARAMETERS);
      });

      it('does not call pingWorkbench', () => {
        expect(pingWorkbench).not.toHaveBeenCalled();
      });

      it('return workbenchConfiguration based on gitlabUrl', () => {
        expect(getGitLabUrl).toHaveBeenCalledWith(TEST_GITLAB_WEB_IDE_PUBLIC_PATH);
        expect(config).toEqual({
          crossOriginExtensionHost: false,
          workbenchBaseUrl: GITLAB_URL,
        });
      });
    });

    describe('when the extensionHostDomain changed', () => {
      let config;

      beforeEach(async () => {
        config = await getWebIDEWorkbenchConfig({
          ...DEFAULT_PARAMETERS,
          extensionHostDomainChanged: true,
        });
      });

      it('appends /assets/webpack to the URL paths', () => {
        expect(config).toEqual({
          crossOriginExtensionHost: true,
          workbenchBaseUrl: `https://workbench-82f9aaae2ef4f6ffb993ca55c2a2eb.${DEFAULT_PARAMETERS.extensionHostDomain}/assets/webpack/gitlab-web-ide-vscode-workbench-${packageJSON.version}`,
          extensionsHostBaseUrl: `https://{{uuid}}.${DEFAULT_PARAMETERS.extensionHostDomain}/assets/webpack/gitlab-web-ide-vscode-workbench-${packageJSON.version}/vscode`,
        });
      });
    });

    describe('when pingWorkbench is successful', () => {
      beforeEach(() => {
        pingWorkbench.mockResolvedValueOnce();
      });

      it('returns workbench configuration based on cdn.web-ide.gitlab-static.net', async () => {
        const config = await getWebIDEWorkbenchConfig(DEFAULT_PARAMETERS);

        expect(pingWorkbench).toHaveBeenCalledWith({
          el: document.body,
          config: {
            workbenchBaseUrl: `https://workbench-82f9aaae2ef4f6ffb993ca55c2a2eb.${DEFAULT_PARAMETERS.extensionHostDomain}/gitlab-web-ide-vscode-workbench-${packageJSON.version}`,
            gitlabUrl: 'https://gitlab.example.com',
          },
        });
        expect(config).toEqual({
          crossOriginExtensionHost: true,
          workbenchBaseUrl: `https://workbench-82f9aaae2ef4f6ffb993ca55c2a2eb.${DEFAULT_PARAMETERS.extensionHostDomain}/gitlab-web-ide-vscode-workbench-${packageJSON.version}`,
          extensionsHostBaseUrl: `https://{{uuid}}.${DEFAULT_PARAMETERS.extensionHostDomain}/gitlab-web-ide-vscode-workbench-${packageJSON.version}/vscode`,
        });
      });
    });

    describe('when pingWebIDE is unsuccessful', () => {
      beforeEach(() => {
        pingWorkbench.mockRejectedValueOnce();
      });

      it('return workbenchConfiguration based on gitlabUrl', async () => {
        const result = await getWebIDEWorkbenchConfig(DEFAULT_PARAMETERS);

        expect(pingWorkbench).toHaveBeenCalledWith({
          el: document.body,
          config: {
            workbenchBaseUrl: `https://workbench-82f9aaae2ef4f6ffb993ca55c2a2eb.${DEFAULT_PARAMETERS.extensionHostDomain}/gitlab-web-ide-vscode-workbench-${packageJSON.version}`,
            gitlabUrl: 'https://gitlab.example.com',
          },
        });
        expect(getGitLabUrl).toHaveBeenCalledWith(TEST_GITLAB_WEB_IDE_PUBLIC_PATH);
        expect(result).toEqual({
          crossOriginExtensionHost: false,
          workbenchBaseUrl: GITLAB_URL,
        });
      });
    });
  });

  describe('buildWorkbenchUrl', () => {
    it.each`
      origin                       | currentUsername               | result
      ${'https://example.com'}     | ${'foobar'}                   | ${'ee2af4a14057872bd8c7463645f503'}
      ${'https://ide.example.com'} | ${'barfoo'}                   | ${'ae3f10e196eac8ef4045e3ec9ba4a5'}
      ${'https://ide.example.com'} | ${'bar.foo'}                  | ${'5bfda1a3ce2b366a1491aba48eba08'}
      ${'https://ide.example.com'} | ${'bar+foo'}                  | ${'b6a09e91b3b97cc3b4f70cf6dfa1dd'}
      ${'https://ide.example.com'} | ${'bar+foo+bar+foo+bar+foo '} | ${'f16f0302f14b7026753d426915bef7'}
    `(
      'returns expected hash when origin is $origin and currentUsername is $currentUsername',
      async ({ origin, currentUsername, result }) => {
        window.location.origin = origin;
        window.gon.current_username = currentUsername;

        expect(await buildWorkbenchUrl(DEFAULT_PARAMETERS)).toBe(
          `https://workbench-${result}.${DEFAULT_PARAMETERS.extensionHostDomain}/gitlab-web-ide-vscode-workbench-${packageJSON.version}`,
        );
      },
    );
  });
});
