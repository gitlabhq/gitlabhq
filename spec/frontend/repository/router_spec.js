import Vue, { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import BlobPage from '~/repository/pages/blob.vue';
import IndexPage from '~/repository/pages/index.vue';
import TreePage from '~/repository/pages/tree.vue';
import createRouter from '~/repository/router';
import { getMatchedComponents } from '~/lib/utils/vue3compat/vue_router';
import { setTitle } from '~/repository/utils/title';

const isVue3 = Vue.version.startsWith('3');

jest.mock('~/repository/utils/title');
jest.mock('jh_else_ce/repository/components/tree_content.vue', () => ({
  name: 'TreeContent',
  template: '<div></div>',
}));
jest.mock('~/repository/components/blob_content_viewer.vue', () => ({
  name: 'BlobContentViewer',
  template: '<div></div>',
}));
jest.mock('~/repository/mixins/preload', () => ({
  default: {},
}));
jest.mock('~/repository/utils/dom');

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
      path                         | expectedPathParam
      ${'/'}                       | ${''}
      ${'/tree/main'}              | ${''}
      ${'/-/tree/main/app/assets'} | ${'app/assets'}
      ${'/-/blob/main/file.md'}    | ${'file.md'}
    `('sets title with correct parameters for $path', async ({ path, expectedPathParam }) => {
      const router = createRouter(projectPath, branch, projectName);

      await router.push(path);

      expect(setTitle).toHaveBeenCalledWith(expectedPathParam, branch, projectName);
    });
  });

  describe('Branch names with special characters', () => {
    it.each`
      path                                | branch           | component   | componentName
      ${'/-/tree/issues/%23101'}          | ${'issues/#101'} | ${TreePage} | ${'TreePage'}
      ${'/-/blob/issues/%23101/file.txt'} | ${'issues/#101'} | ${BlobPage} | ${'BlobPage'}
      ${'/-/tree/feat%23test'}            | ${'feat#test'}   | ${TreePage} | ${'TreePage'}
      ${'/-/blob/feat%23test/README.md'}  | ${'feat#test'}   | ${BlobPage} | ${'BlobPage'}
    `(
      'encodes special characters in branch "$branch" and matches path "$path" to $componentName',
      ({ path, component, branch }) => {
        const router = createRouter('', branch);

        const componentsForRoute = getMatchedComponents(router, path);

        expect(componentsForRoute).toEqual([component]);
      },
    );
  });

  describe('Component reactivity with route changes', () => {
    const PROJECT_PATH = 'project';
    const BRANCH = 'master';
    const REF_TYPE = 'heads';

    const createRouterAndNavigate = async (initialRoute) => {
      const router = createRouter(PROJECT_PATH, BRANCH);
      await router.push(initialRoute);
      return router;
    };

    const mountBlobPage = (router, path) =>
      shallowMount(BlobPage, {
        router,
        propsData: {
          path,
          projectPath: PROJECT_PATH,
          refType: REF_TYPE,
        },
      });

    it.each`
      component     | initialRoute                  | initialPath    | targetRoute                     | targetPath       | description
      ${'BlobPage'} | ${'/-/blob/master/README.md'} | ${'README.md'} | ${'/-/tree/master/'}            | ${'/'}           | ${'file to root'}
      ${'BlobPage'} | ${'/-/blob/master/README.md'} | ${'README.md'} | ${'/-/blob/master/ADOPTERS.md'} | ${'ADOPTERS.md'} | ${'between files'}
    `(
      '$component computedPath updates when route changes from $description',
      async ({ initialRoute, initialPath, targetRoute, targetPath }) => {
        const router = await createRouterAndNavigate(initialRoute);
        const wrapper = mountBlobPage(router, initialPath);

        await nextTick();

        expect(wrapper.vm.computedPath).toBe(initialPath);
        expect(wrapper.vm.$route.path).toBe(initialRoute);
        expect(wrapper.vm.$route.params.path).toBe(initialPath);

        await router.push(targetRoute);
        await nextTick();

        expect(wrapper.vm.$route.path).toBe(targetRoute);
        let expectedParamValue;
        // Vue 2 returns undefined, Vue 3 returns '' for optional params with no value
        if (isVue3) {
          expectedParamValue = targetPath === '/' ? '' : targetPath;
        } else {
          expectedParamValue = targetPath === '/' ? undefined : targetPath;
        }
        expect(wrapper.vm.$route.params.path).toBe(expectedParamValue);
        expect(wrapper.vm.computedPath).toBe(targetPath);
      },
    );

    it('TreePage isRoot computed updates when navigating to/from root', async () => {
      const router = createRouter(PROJECT_PATH, BRANCH);
      const wrapper = shallowMount(TreePage, {
        router,
        propsData: {
          path: PROJECT_PATH,
          refType: REF_TYPE,
        },
        data() {
          return {
            loadingPath: '',
          };
        },
      });

      await router.push('/-/tree/master/');
      await nextTick();
      expect(wrapper.vm.isRoot).toBe(true);

      await router.push('/-/blob/master/README.md');
      await nextTick();
      expect(wrapper.vm.isRoot).toBe(false);

      await router.push('/-/tree/master/');
      await nextTick();

      expect(wrapper.vm.isRoot).toBe(true);
    });
  });
});
