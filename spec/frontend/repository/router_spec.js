import BlobPage from '~/repository/pages/blob.vue';
import IndexPage from '~/repository/pages/index.vue';
import TreePage from '~/repository/pages/tree.vue';
import createRouter from '~/repository/router';
import { getMatchedComponents } from '~/lib/utils/vue3compat/vue_router';
import { setTitle } from '~/repository/utils/title';

jest.mock('~/repository/utils/title');

describe('Repository router spec', () => {
  it.each`
    path                         | branch          | component    | componentName
    ${'/'}                       | ${'main'}       | ${IndexPage} | ${'IndexPage'}
    ${'/tree/main'}              | ${'main'}       | ${TreePage}  | ${'TreePage'}
    ${'/tree/feat(test)'}        | ${'feat(test)'} | ${TreePage}  | ${'TreePage'}
    ${'/-/tree/main'}            | ${'main'}       | ${TreePage}  | ${'TreePage'}
    ${'/-/tree/main/app/assets'} | ${'main'}       | ${TreePage}  | ${'TreePage'}
    ${'/-/blob/main/file.md'}    | ${'main'}       | ${BlobPage}  | ${'BlobPage'}
  `('sets component as $componentName for path "$path"', ({ path, component, branch }) => {
    const router = createRouter('', branch);

    const componentsForRoute = getMatchedComponents(router, path);

    expect(componentsForRoute).toEqual([component]);
  });

  describe('Storing Web IDE path globally', () => {
    const proj = 'foo-bar-group/foo-bar-proj';
    let originalGl;

    beforeEach(() => {
      originalGl = window.gl;
    });

    afterEach(() => {
      window.gl = originalGl;
    });

    it.each`
      path                         | branch          | expectedPath
      ${'/'}                       | ${'main'}       | ${`/-/ide/project/${proj}/edit/main/-/`}
      ${'/tree/main'}              | ${'main'}       | ${`/-/ide/project/${proj}/edit/main/-/`}
      ${'/tree/feat(test)'}        | ${'feat(test)'} | ${`/-/ide/project/${proj}/edit/feat(test)/-/`}
      ${'/-/tree/main'}            | ${'main'}       | ${`/-/ide/project/${proj}/edit/main/-/`}
      ${'/-/tree/main/app/assets'} | ${'main'}       | ${`/-/ide/project/${proj}/edit/main/-/app/assets/`}
      ${'/-/blob/main/file.md'}    | ${'main'}       | ${`/-/ide/project/${proj}/edit/main/-/file.md`}
    `(
      'generates the correct Web IDE url for $path',
      async ({ path, branch, expectedPath } = {}) => {
        const router = createRouter(proj, branch);

        await router.push(path);
        expect(window.gl.webIDEPath).toBe(expectedPath);
      },
    );
  });

  describe('Setting page title', () => {
    const projectPath = 'group/project';
    const projectName = 'Project Name';
    const branch = 'main';

    it.each`
      path                         | expectedPath
      ${'/'}                       | ${'/'}
      ${'/tree/main'}              | ${'/'}
      ${'/-/tree/main/app/assets'} | ${'app/assets'}
      ${'/-/blob/main/file.md'}    | ${'file.md'}
    `('sets title with correct parameters for $path', async ({ path, expectedPath }) => {
      const router = createRouter(projectPath, branch, projectName);

      await router.push(path);

      expect(setTitle).toHaveBeenCalledWith(expectedPath, branch, projectName);
    });
  });
});
