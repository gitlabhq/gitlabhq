import { shallowMount } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import PackagePath from '~/packages_and_registries/shared/components/package_path.vue';

describe('PackagePath', () => {
  let wrapper;

  const mountComponent = (propsData = { path: 'foo' }) => {
    wrapper = shallowMount(PackagePath, {
      propsData,
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const BASE_ICON = 'base-icon';
  const ROOT_LINK = 'root-link';
  const ROOT_CHEVRON = 'root-chevron';
  const ELLIPSIS_ICON = 'ellipsis-icon';
  const ELLIPSIS_CHEVRON = 'ellipsis-chevron';
  const LEAF_LINK = 'leaf-link';

  const findItem = (name) => wrapper.find(`[data-testid="${name}"]`);
  const findTooltip = (w) => getBinding(w.element, 'gl-tooltip');

  describe.each`
    path                       | rootUrl       | shouldExist                                                   | shouldNotExist
    ${'foo/bar'}               | ${'/foo/bar'} | ${[]}                                                         | ${[ROOT_CHEVRON, ELLIPSIS_ICON, ELLIPSIS_CHEVRON, LEAF_LINK]}
    ${'foo/bar/baz'}           | ${'/foo/bar'} | ${[ROOT_CHEVRON, LEAF_LINK]}                                  | ${[ELLIPSIS_ICON, ELLIPSIS_CHEVRON]}
    ${'foo/bar/baz/baz2'}      | ${'/foo/bar'} | ${[ROOT_CHEVRON, LEAF_LINK, ELLIPSIS_ICON, ELLIPSIS_CHEVRON]} | ${[]}
    ${'foo/bar/baz/baz2/bar2'} | ${'/foo/bar'} | ${[ROOT_CHEVRON, LEAF_LINK, ELLIPSIS_ICON, ELLIPSIS_CHEVRON]} | ${[]}
  `('given path $path', ({ path, shouldExist, shouldNotExist, rootUrl }) => {
    const pathPieces = path.split('/').slice(1);
    const hasTooltip = shouldExist.includes(ELLIPSIS_ICON);

    describe('not disabled component', () => {
      beforeEach(() => {
        mountComponent({ path });
      });

      it('should have a base icon', () => {
        expect(findItem(BASE_ICON).exists()).toBe(true);
      });

      it('should have a root link', () => {
        const root = findItem(ROOT_LINK);
        expect(root.exists()).toBe(true);
        expect(root.attributes('href')).toBe(rootUrl);
      });

      if (hasTooltip) {
        it('should have a tooltip', () => {
          const tooltip = findTooltip(findItem(ELLIPSIS_ICON));
          expect(tooltip).toBeDefined();
          expect(tooltip.value).toMatchObject({
            title: path,
          });
        });
      }

      if (shouldExist.length) {
        it.each(shouldExist)(`should have %s`, (element) => {
          expect(findItem(element).exists()).toBe(true);
        });
      }

      if (shouldNotExist.length) {
        it.each(shouldNotExist)(`should not have %s`, (element) => {
          expect(findItem(element).exists()).toBe(false);
        });
      }

      if (shouldExist.includes(LEAF_LINK)) {
        it('the last link should be the last piece of the path', () => {
          const leaf = findItem(LEAF_LINK);
          expect(leaf.attributes('href')).toBe(`/${path}`);
          expect(leaf.text()).toBe(pathPieces[pathPieces.length - 1]);
        });
      }
    });

    describe('disabled component', () => {
      beforeEach(() => {
        mountComponent({ path, disabled: true });
      });

      it('root link is disabled', () => {
        expect(findItem(ROOT_LINK).attributes('disabled')).toBeDefined();
      });

      if (shouldExist.includes(LEAF_LINK)) {
        it('the last link is disabled', () => {
          expect(findItem(LEAF_LINK).attributes('disabled')).toBeDefined();
        });
      }
    });
  });
});
