import { shallowMount } from '@vue/test-utils';
import TreePage from '~/repository/pages/tree.vue';
import TreeContent from 'jh_else_ce/repository/components/tree_content.vue';
import { updateElementsVisibility } from '~/repository/utils/dom';

jest.mock('~/repository/utils/dom');

describe('Repository tree page component', () => {
  let wrapper;

  const findTreeContent = () => wrapper.findComponent(TreeContent);

  function factory(propsData = {}, routePath = undefined) {
    wrapper = shallowMount(TreePage, {
      propsData,
      mocks: {
        $route: {
          params: { path: routePath },
        },
      },
    });
  }

  afterEach(() => {
    updateElementsVisibility.mockClear();
  });

  it('uses computedPath from mixin to get path from route', () => {
    factory({}, 'src/components/active.vue');

    expect(findTreeContent().props('path')).toBe('src/components/active.vue');
  });

  describe('when root path', () => {
    beforeEach(() => {
      factory({}, undefined);
    });

    it('shows root elements', () => {
      expect(updateElementsVisibility.mock.calls).toEqual([
        ['.js-show-on-root', true],
        ['.js-hide-on-root', false],
      ]);
    });
  });

  describe('when non-root path', () => {
    beforeEach(() => {
      factory({}, 'test');
    });

    it('hides root elements', () => {
      expect(updateElementsVisibility.mock.calls).toEqual([
        ['.js-show-on-root', false],
        ['.js-hide-on-root', true],
      ]);
    });
  });
});
