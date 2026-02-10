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
    workbenchSecret: 'test-workbench-secret',
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
          workbenchBaseUrl: `https://workbench-8add8b75fc742d5750d43812940476.${DEFAULT_PARAMETERS.extensionHostDomain}/assets/webpack/gitlab-web-ide-vscode-workbench-${packageJSON.version}`,
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
            workbenchBaseUrl: `https://workbench-8add8b75fc742d5750d43812940476.${DEFAULT_PARAMETERS.extensionHostDomain}/gitlab-web-ide-vscode-workbench-${packageJSON.version}`,
            gitlabUrl: 'https://gitlab.example.com',
          },
        });
        expect(config).toEqual({
          crossOriginExtensionHost: true,
          workbenchBaseUrl: `https://workbench-8add8b75fc742d5750d43812940476.${DEFAULT_PARAMETERS.extensionHostDomain}/gitlab-web-ide-vscode-workbench-${packageJSON.version}`,
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
            workbenchBaseUrl: `https://workbench-8add8b75fc742d5750d43812940476.${DEFAULT_PARAMETERS.extensionHostDomain}/gitlab-web-ide-vscode-workbench-${packageJSON.version}`,
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
      ${'https://example.com'}     | ${'foobar'}                   | ${'d4365bb86884fedd38d5e09292f2a4'}
      ${'https://ide.example.com'} | ${'barfoo'}                   | ${'b3e0e5b6ae3440ffe52adf13f1efe1'}
      ${'https://ide.example.com'} | ${'bar.foo'}                  | ${'5efe21f7e4fe8ffd51a899481dd219'}
      ${'https://ide.example.com'} | ${'bar+foo'}                  | ${'ac3e4ac35294fb6934629fa8c8c89c'}
      ${'https://ide.example.com'} | ${'bar+foo+bar+foo+bar+foo '} | ${'fe9fa97636130fbdb284ff5dc20a22'}
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
