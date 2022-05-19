import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import projectImportGitlab from '~/projects/project_import_gitlab_project';

describe('Import Gitlab project', () => {
  const pathName = 'my-project';
  const projectName = 'My Project';

  const setTestFixtures = (url) => {
    window.history.pushState({}, null, url);

    setHTMLFixture(`
      <input class="js-path-name" />
      <input class="js-project-name" />
    `);

    projectImportGitlab();
  };

  beforeEach(() => {
    setTestFixtures(`?name=${projectName}&path=${pathName}`);
  });

  afterEach(() => {
    window.history.pushState({}, null, '');
    resetHTMLFixture();
  });

  describe('project name', () => {
    it('should fill in the project name derived from the previously filled project name', () => {
      expect(document.querySelector('.js-project-name').value).toEqual(projectName);
    });

    describe('empty path name', () => {
      it('derives the path name from the previously filled project name', () => {
        const alternateProjectName = 'My Alt Project';
        const alternatePathName = 'my-alt-project';

        setTestFixtures(`?name=${alternateProjectName}`);

        expect(document.querySelector('.js-path-name').value).toEqual(alternatePathName);
      });
    });
  });

  describe('path name', () => {
    it('should fill in the path name derived from the previously filled path name', () => {
      expect(document.querySelector('.js-path-name').value).toEqual(pathName);
    });

    describe('empty project name', () => {
      it('derives the project name from the previously filled path name', () => {
        const alternateProjectName = 'My Alt Project';
        const alternatePathName = 'my-alt-project';

        setTestFixtures(`?path=${alternatePathName}`);

        expect(document.querySelector('.js-project-name').value).toEqual(alternateProjectName);
      });
    });
  });
});
