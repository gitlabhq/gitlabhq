import { visitUrl, webIDEUrl } from '~/lib/utils/url_utility';
import { openWebIDE } from '~/lib/utils/web_ide_navigator';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
  webIDEUrl: jest.fn().mockImplementation((path) => `/-/ide/projects${path}`),
}));

describe('openWebIDE', () => {
  it('when called without projectPath throws TypeError and does not call visitUrl', () => {
    expect(() => {
      openWebIDE();
    }).toThrow(new TypeError('projectPath parameter is required'));
    expect(visitUrl).not.toHaveBeenCalled();
  });

  it('when called with projectPath and without fileName calls visitUrl with correct path', () => {
    const params = { projectPath: 'project-path' };
    const expectedNonIDEPath = `/${params.projectPath}/edit/main/-/`;
    const expectedIDEPath = `/-/ide/projects${expectedNonIDEPath}`;

    openWebIDE(params.projectPath);

    expect(webIDEUrl).toHaveBeenCalledWith(expectedNonIDEPath);
    expect(visitUrl).toHaveBeenCalledWith(expectedIDEPath);
  });

  it('when called with projectPath and fileName calls visitUrl with correct path', () => {
    const params = { projectPath: 'project-path', fileName: 'README' };
    const expectedNonIDEPath = `/${params.projectPath}/edit/main/-/${params.fileName}/`;
    const expectedIDEPath = `/-/ide/projects${expectedNonIDEPath}`;

    openWebIDE(params.projectPath, params.fileName);

    expect(webIDEUrl).toHaveBeenCalledWith(expectedNonIDEPath);
    expect(visitUrl).toHaveBeenCalledWith(expectedIDEPath);
  });
});
