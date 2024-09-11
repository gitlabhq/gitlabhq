import nodePath from 'node:path';
import nodeFs from 'node:fs/promises';

describe('asset patching in @gitlab/web-ide', () => {
  const PATH_PUBLIC_VSCODE = nodePath.join(
    nodePath.dirname(require.resolve('@gitlab/web-ide')),
    'public/vscode',
  );
  const PATH_EXTENSION_HOST_HTML = nodePath.join(
    PATH_PUBLIC_VSCODE,
    'out/vs/workbench/services/extensions/worker/webWorkerExtensionHostIframe.html',
  );

  it('prevents xss by patching parentOrigin in webIdeExtensionHost.html', async () => {
    const content = await nodeFs.readFile(PATH_EXTENSION_HOST_HTML, { encoding: 'utf-8' });

    // https://gitlab.com/gitlab-org/security/gitlab-web-ide-vscode-fork/-/issues/1#note_1905417620
    expect(content).toContain('const parentOrigin = window.origin;');
  });

  it('doesnt have extraneous html files', async () => {
    const allChildren = await nodeFs.readdir(PATH_PUBLIC_VSCODE, {
      encoding: 'utf-8',
      recursive: true,
    });
    const htmlChildren = allChildren.filter((x) => x.endsWith('.html'));

    expect(htmlChildren).toEqual([
      // This is the only HTML file we expect and it's protected by the other test.
      'out/vs/workbench/services/extensions/worker/webWorkerExtensionHostIframe.html',
      // HTML files from "extensions" should be safe (since they only work in an extension host environment really).
      // We're going to list them out here though to err on the side of caution.
      'extensions/microsoft-authentication/media/index.html',
      'extensions/gitlab-vscode-extension/webviews/security_finding/index.html',
      'extensions/gitlab-vscode-extension/webviews/gitlab_duo_chat/index.html',
      'extensions/github-authentication/media/index.html',
    ]);
  });
});
